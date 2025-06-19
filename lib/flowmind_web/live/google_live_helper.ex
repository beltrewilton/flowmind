defmodule GmailReader do
  alias GoogleApi.Gmail.V1.Api.Users
  alias GoogleApi.Gmail.V1.Connection
  alias GoogleApi.Gmail.V1.Model.ListMessagesResponse

  def list_messages(access_token, limit \\ 10) do
    conn = make_conn(access_token)

    case Users.gmail_users_messages_list(conn, "me", maxResults: limit) do
      {:ok, %ListMessagesResponse{messages: messages}} -> {:ok, messages || []}
      {:error, error} -> {:error, error}
    end
  end

  def get_message(access_token, msg_id) do
    conn = make_conn(access_token)
    Users.gmail_users_messages_get(conn, "me", msg_id, format: "full")
  end

  defp make_conn(access_token) do
    Connection.new(access_token)
  end
end

defmodule FlowmindWeb.GoogleLiveHelper do
  use FlowmindWeb, :live_view

  def doc, do: "Google login and callback handler for Flowmind."

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, status: :idle, greeting: nil, messages_pair: [], google_account: nil)}
  end

  @impl true
  def handle_params(%{"code" => code} = params, _uri, socket) do
    IO.inspect(code, label: "OAuth code received from Google")

    # Async task to avoid blocking LiveView mount
    send(self(), {:exchange_token, code})

    {:noreply, assign(socket, code: code, status: :exchanging)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, status: :idle)}
  end

  @impl true
  def handle_info({:exchange_token, code}, socket) do
    case exchange_code_for_token(code) do
      {:ok, token} ->
        access_token = Jason.decode!(token.access_token)
        IO.inspect(access_token, label: "Google token success")

        case fetch_user_info(access_token["access_token"]) do
          {:ok, google_account} ->
            # Save `user["email"]` in your DB here!
            IO.inspect(google_account, label: "Google User Info")

            # Fetch Gmail messages
            {:ok, messages_pair} = fetch_gmail_messages(access_token["access_token"])

            IO.inspect(messages_pair)

            {:noreply,
             assign(socket,
               status: :success,
               google_account: google_account,
               messages_pair: messages_pair
             )}

          {:error, reason} ->
            {:noreply, assign(socket, status: :error, error: reason)}
        end

      {:error, reason} ->
        IO.inspect(reason, label: "Google token failed")
        {:noreply, assign(socket, status: :error, error: reason)}
    end
  end

  @impl true
  def handle_event("compile_say_hello", _data, socket) do
    IO.inspect("compile_say_hello")
    [{module, _bin}] = Code.compile_file("/Users/beltre.wilton/apps/temp/addons/say_hello.ex")

    {:noreply, socket}
  end

  @impl true
  def handle_event("_say_hello", _data, socket) do
    greeting =
      case Code.ensure_loaded(FlowmindWeb.Addons.SayHello) do
        {:error, _} -> "Module not compiled yet."
        {:module, _} -> FlowmindWeb.Addons.SayHello.say_hello()
      end

    {:noreply, assign(socket, greeting: greeting)}
  end

  defp exchange_code_for_token(code) do
    # OAuth2 client for Google
    client =
      OAuth2.Client.new(
        strategy: OAuth2.Strategy.AuthCode,
        client_id: System.fetch_env!("GOOGLE_CALENDAR_CLIENT_ID"),
        client_secret: System.fetch_env!("GOOGLE_CALENDAR_CLIENT_SECRET"),
        redirect_uri: "https://flowmind.loca.lt/google_helper",
        site: "https://accounts.google.com",
        authorize_url: "https://accounts.google.com/o/oauth2/auth",
        token_url: "https://oauth2.googleapis.com/token"
      )

    # Exchange code for token
    client
    |> OAuth2.Client.get_token(code: code)
    |> case do
      {:ok, %{token: token}} -> {:ok, token}
      error -> {:error, error}
    end
  end

  defp google_auth_url do
    client_id = System.fetch_env!("GOOGLE_CALENDAR_CLIENT_ID")
    redirect_uri = URI.encode("https://flowmind.loca.lt/google_helper")

    scope =
      URI.encode(
        "https://www.googleapis.com/auth/calendar.events https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/gmail.readonly"
      )

    "https://accounts.google.com/o/oauth2/auth" <>
      "?client_id=#{client_id}" <>
      "&redirect_uri=#{redirect_uri}" <>
      "&response_type=code" <>
      "&scope=#{scope}" <>
      "&access_type=offline" <>
      "&prompt=consent"
  end

  defp fetch_user_info(access_token) do
    IO.inspect(access_token, label: "Access Token for User Info")

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Accept", "application/json"}
    ]

    request =
      Finch.build(:get, "https://www.googleapis.com/oauth2/v3/userinfo", headers)

    case Finch.request(request, Flowmind.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        IO.inspect(body, label: "User Info Response")

        case Jason.decode(body) do
          {:ok, user_info} -> {:ok, user_info}
          error -> {:error, error}
        end

      {:ok, %Finch.Response{status: status, body: body}} ->
        IO.inspect(body, label: "Unexpected User Info Response")
        {:error, "Unexpected response (#{status}): #{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_gmail_messages(access_token) do
    {:ok, messages} = GmailReader.list_messages(access_token, 4)

    ids = Enum.map(messages, & &1.id)

    messages_pair =
      Enum.map(ids, fn id ->
        case GmailReader.get_message(access_token, id) do
          {:ok, message} ->
            # IO.inspect data, label: "Raw Data for ID: #{id}"
            case message.payload.body.data do
              nil ->
                IO.inspect("No body data for message ID: #{id}")
                {id, "No body data"}

              data ->
                {:ok, raw} =
                  data
                  |> String.replace("-", "+")
                  |> String.replace("_", "/")
                  |> Base.decode64(padding: false)

                text =
                  Floki.parse_document!(raw)
                  |> Floki.filter_out("style, script, head")
                  |> Floki.text(sep: " ")
                  |> String.replace(~r/\s+/u, " ")
                  
                sender = message.payload.headers |> Enum.filter(fn h -> h.name == "From" end) |> List.first()

                {id, text, sender}
            end

          {:error, error} ->
            IO.inspect(error, label: "Error fetching message for ID: #{id}")
        end
      end)

    {:ok, messages_pair}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div :if={@google_account} class="flex w-full col-2 gap-1 pl-1 pb-4">
      <.avatar online>
        <div class="w-12 rounded-full">
          <img src={@google_account["picture"]} />
        </div>
      </.avatar>
      <span  class="w-full text-xl pl-3">
        {@google_account["name"]}
      </span>
    </div>
    
    <div class="p-4">
      <%= case @status do %>
        <% :idle -> %>
          <div>
            <h2 class="text-xl font-semibold mb-2">Connect Your Google Account</h2>
            <a
              href={google_auth_url()}
              class="bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded"
            >
              Connect with Google
            </a>
          </div>
        <% :exchanging -> %>
          <div>Exchanging code for token...</div>
        <% :success -> %>
          <div class="text-green-600">✅ Successfully connected with Google!</div>
        <% :error -> %>
          <div class="text-red-600">❌ Error: {inspect(@error)}</div>
        <% _ -> %>
          <div>Unknown state.</div>
      <% end %>
    </div>
    
      <%= for {id, snippet, sender} <- @messages_pair do %>
        <.card class="bg-base-200 w-120 shadow-xl mb-5">
          <:card_title>{sender.value}</:card_title>
          <:card_body>
            <p>{snippet}</p>
          </:card_body>
        </.card>
      <% end %>

    <.alert :if={@greeting} id="alert-single-info">
      <.icon name="hero-exclamation-circle" /> {@greeting}
    </.alert>
    """
  end
end
