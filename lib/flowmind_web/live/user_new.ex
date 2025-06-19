defmodule FlowmindWeb.UserNewLive do
  use FlowmindWeb, :live_view
  alias Flowmind.Accounts
  alias Flowmind.Accounts.User

  def doc do
    "UserNewLive"
  end

  @impl true
  def mount(_params, _session, socket) do
    tenant = Flowmind.TenantContext.get_tenant()

    user_changeset = Accounts.user_company_changeset(%User{})

    socket =
      socket
      |> assign(:tenant, tenant)
      |> assign(:tenant_accounts, [])
      |> assign_form(user_changeset)

    {:ok, socket}
  end

  def handle_event("send", user_form, socket) do
    current_user = socket.assigns.current_user
    user_form = Map.get(user_form, "user_form")
    user_form = user_form |> Map.put("role", :employee)
    IO.inspect(user_form, label: "user_form")

    {:ok, user} = Accounts.register_user(user_form)
    Accounts.update_user_company(user, current_user.company)

    {:ok, _} =
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )

    socket =
      socket
      |> push_navigate(to: ~p"/userprofile/#{user.id}")

    {:noreply, socket}
  end

  def handle_event("validate", %{"user_form" => user_form}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_form)

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    IO.inspect(params, label: ">params")
    {:noreply, socket}
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "user_form"))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.breadcrumbs class="pl-5">
      <:item icon="hero-users"><.link patch={~p"/userlist"}>Users</.link></:item>
      <:item>Add New User</:item>
    </.breadcrumbs>
    <div class="p-5">
      <div class="text-xl mb-4">Add New User</div>
      <.simple_form
        for={@form}
        id="user-new-form"
        phx-submit="send"
        phx-change="validate"
        class="w-full"
      >
        <.avatar class="mb-1">
          <div class="mask mask-squircle w-16">
            <img src="https://img.daisyui.com/images/stock/photo-1534528741775-53994a69daeb.webp" />
          </div>
        </.avatar>
        <div class="divider"></div>
        <div phx-mounted={JS.focus(to: "#full-name-id")}>Personal Information</div>
        <.live_component
          module={FlowmindWeb.Live.InputIconComponent}
          id="input-full-name-id"
          form={@form}
          formvar={:name}
          icon_name="hero-user"
          ilabel="Full name"
          iid="full-name-id"
        />
        <.live_component
          module={FlowmindWeb.Live.InputIconComponent}
          id="input-email-id"
          form={@form}
          formvar={:email}
          icon_name="hero-envelope"
          ilabel="Email"
        />
        <.live_component
          module={FlowmindWeb.Live.InputIconComponent}
          id="input-password-id"
          form={@form}
          formvar={:password}
          icon_name="hero-key"
          ilabel="Password"
          itype="password"
        />
        <:actions>
          <div class="flex justify-end w-full">
            <.button color="primary" class="w-1/4 mt-4 hover:bg-blue-600 transition duration-300">
              Save <.icon name="hero-cloud-arrow-up" />
            </.button>
          </div>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
