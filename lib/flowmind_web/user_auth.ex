defmodule FlowmindWeb.UserAuth do
  use FlowmindWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  # alias Ecto.Repo
  alias Flowmind.Accounts
  alias Flowmind.Chat

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_flowmind_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: user_return_to || signed_in_path(conn))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_user_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      FlowmindWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    Flowmind.TenantGenServer.remove_tenant()

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def fetch_current_user(conn, _opts) do
    IO.inspect("fetch_current_user")
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    user = Flowmind.Repo.preload(user, :company)
    tenant = get_user_tenant(user)
    IO.inspect(tenant, label: "tenant fetch_current_user")
    user = Flowmind.Repo.preload(user, :customers, prefix: tenant)

    Flowmind.TenantContext.put_tenant(tenant)

    conn
    |> assign(:current_user, user)
  end

  defp get_user_tenant(user) do
    fallback_tenant(user)
  end

  defp fallback_tenant(nil), do: "not_loaded"
  defp fallback_tenant(user), do: user.company.tenant


  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Handles mounting and authenticating the current_user in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_user` - Assigns current_user
      to socket assigns based on user_token, or nil if
      there's no user_token or no matching user.

    * `:ensure_authenticated` - Authenticates the user from the session,
      and assigns the current_user to socket assigns based
      on user_token.
      Redirects to login page if there's no logged user.

    * `:redirect_if_user_is_authenticated` - Authenticates the user from the session.
      Redirects to signed_in_path if there's a logged user.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the current_user:

      defmodule FlowmindWeb.PageLive do
        use FlowmindWeb, :live_view

        on_mount {FlowmindWeb.UserAuth, :mount_current_user}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{FlowmindWeb.UserAuth, :ensure_authenticated}] do
        live "/profile", ProfileLive, :index
      end
  """
  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/users/log_in")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  def on_mount(
        :ensure_admin_or_user,
        _params,
        _session,
        %{assigns: %{current_user: user}} = socket
      ) do
    if user.role in [:admin, :user] do
      {:cont, socket}
    else
      {:halt,
       socket
       |> Phoenix.LiveView.put_flash(:error, "fail ensure_admin_or_user")
       |> Phoenix.LiveView.redirect(to: "/not_authorized?msg=ensure_admin_or_user")}
    end
  end

  def on_mount(
        :load_chat_inbox,
        _params,
        _session,
        %{assigns: %{current_user: user}} = socket
      ) do
    chat_inbox = Chat.list_chat_inbox(user)

    socket =
      socket
      |> Phoenix.Component.assign(:chat_inbox, chat_inbox)

    {:cont, socket}
  end

  def on_mount(
        :ensure_has_phone_number_id,
        params,
        _session,
        socket
      ) do
    phone_number_id = Map.get(params, "phone_number_id")
    tenant_account = Accounts.get_tenant_account_by_phone_number_id(phone_number_id)

    if is_nil(tenant_account) do
      {:halt,
       socket
       |> Phoenix.LiveView.put_flash(:error, "fail ensure_has_phone_number_id")
       |> Phoenix.LiveView.redirect(to: "/not_authorized?msg=ensure_has_phone_number_id")}
    else
      {:cont, socket}
    end
  end

  def on_mount(
        :ensure_has_customer,
        params,
        _session,
        %{assigns: %{current_user: user}} = socket
      ) do
    sender_phone_number = Map.get(params, "sender_phone_number")
    phone_number_id = Map.get(params, "phone_number_id")
    IO.inspect(phone_number_id, label: "phone_number_id:origin")

    has_phone_number? =
      Enum.any?(user.customers, fn customer ->
        customer.phone_number == sender_phone_number
      end)

    if has_phone_number? do
      {:cont, socket}
    else
      {:halt,
       socket
       |> Phoenix.LiveView.put_flash(:error, "fail ensure_has_customer")
       |> Phoenix.LiveView.redirect(to: "/not_authorized?msg=ensure_has_customer")}
    end
  end

  defp mount_current_user(socket, session) do
    IO.inspect("mount_current_user")
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user_token = session["user_token"] do
        user = Accounts.get_user_by_session_token(user_token) |> Flowmind.Repo.preload(:company)
        
        if Phoenix.LiveView.connected?(socket) do
            FlowmindWeb.Presence.track(
              self(),
              "liveview_connections",
              socket.id,
              %{
                user_id: user.id,
                tenant: user.company.tenant,
                phone_number_id: user.company.phone_number_id
              }
            )
        end
        Flowmind.TenantContext.put_tenant(user.company.tenant)
        tenant = Flowmind.TenantContext.get_tenant()
        IO.inspect(tenant, label: "tenant mount_current_user")
        Flowmind.Repo.preload(user, :customers, prefix: tenant)
      end
    end)
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/log_in")
      |> halt()
    end
  end

  def by_pass_live(conn, _opts) do
    conn
  end

  def by_pass_live_1(conn, _opts) do
    conn
  end

  def by_pass_live_2(conn, _opts) do
    conn
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/dashboard"
end
