defmodule FlowmindWeb.ChatLive do
  use FlowmindWeb, :live_view

  alias Flowmind.Chat
  alias Phoenix.PubSub
  alias Flowmind.Chat.ChatHistory
  alias FlowmindWeb.ChatPubsub

  def doc do
    "Chat"
  end

  @impl true
  def mount(params, _session, socket) do
    IO.inspect(params, label: "params")
    sender_phone_number = Map.get(params, "sender_phone_number")

    if connected?(socket), do: ChatPubsub.subscribe(sender_phone_number)

    # TODO:
    display_phone_number = "18496577713"
    if connected?(socket), do: ChatPubsub.subscribe(display_phone_number)

    # chat_history = Chat.list_chat_history(sender_phone_number)

    chat_inbox = Chat.list_chat_inbox()

    form_source = Chat.change_chat_history(%ChatHistory{})

    tenant = Flowmind.TenantGenServer.get_tenant()

    socket =
      socket
      |> assign(:chat_history, [])
      |> assign(:chat_inbox, chat_inbox)
      |> assign(:tenant, tenant)
      |> assign(:tenant_accounts, [])
      |> assign(:sender_phone_number, sender_phone_number)
      |> assign_form(form_source)
      |> push_event("scrolldown", %{value: 1})

    {:ok, socket, layout: {FlowmindWeb.ChatLayouts, :app}}
  end

  @impl true
  def handle_event("send", %{"chat_history_form" => chat_history_form}, socket) do
    IO.inspect(chat_history_form, label: "chat_history_form")
    sender_phone_number = socket.assigns.sender_phone_number

    chat_history_form = Map.put(chat_history_form, "source", :agent)
    chat_history_form = Map.put(chat_history_form, "sender_phone_number", sender_phone_number)

    WhatsappElixir.Messages.send_message(
      sender_phone_number,
      # TODO:
      "606765489182594",
      chat_history_form["message"],
      WhatsappElixir.Messages.get_config()
    )

    Chat.create_chat_history(chat_history_form)
    |> ChatPubsub.notify(:message_created, sender_phone_number)

    # chat_history = Chat.list_chat_history()

    # socket =
    #   socket
    #   |> assign(:chat_history, chat_history)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:message_created, message}, socket) do
    IO.inspect("No acredito!", label: "WOW")
    chat_history = socket.assigns.chat_history ++ [message]

    socket =
      socket
      |> assign(chat_history: chat_history)
      |> push_event("scrolldown", %{value: 1})

    {:noreply, socket}
  end

  @impl true
  def handle_info({:refresh_inbox, message}, socket) do
    chat_inbox = socket.assigns.chat_inbox ++ [message]

    phone_number_id = message.phone_number_id

    IO.inspect(message, label: "refresh_inbox chat_inbox")

    socket =
      socket
      |> assign(chat_inbox: chat_inbox)
      |> assign(phone_number_id: phone_number_id)

    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    sender_phone_number = params["sender_phone_number"]
    old_sender_phone_number = socket.assigns.sender_phone_number
    chat_inbox = socket.assigns.chat_inbox

    IO.inspect(DateTime.utc_now(), label: "DateTime.utc_now()")
    IO.inspect(sender_phone_number, label: "sender_phone_number")
    IO.inspect(old_sender_phone_number, label: "old_sender_phone_number")
    
    # inbox = Enum.find(chat_inbox, fn chat -> chat.sender_phone_number == sender_phone_number end)


    if connected?(socket) do
      ChatPubsub.unsubscribe(old_sender_phone_number)
      ChatPubsub.subscribe(sender_phone_number)
    end

    chat_history = Chat.list_chat_history(sender_phone_number)

    # IO.inspect(chat_history, label: "chat_history")

    socket =
      socket
      |> assign(:chat_inbox, chat_inbox)
      |> assign(:chat_history, chat_history)
      |> assign(:sender_phone_number, sender_phone_number)
      |> push_event("scrolldown", %{value: 1})

    {:noreply, socket}
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "chat_history_form"))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-[90vh]">
      <div class="w-[65%]  overflow-y-auto" id="chat-messages" phx-hook="ScrolltoBottom">
        <%= for chat <- @chat_history do %>
          <% chat_css = if chat.source == :user, do: 'chat-start', else: 'chat-end' %>
          <div class={"chat m-5 #{chat_css}"}>
            <div class="chat-image avatar">
              <div class="w-10 rounded-full">
                <img
                  :if={chat.source == :user}
                  alt="Tailwind CSS chat bubble component"
                  src={"https://i.pravatar.cc/150?u=#{chat.sender_phone_number}"}
                />
                <img
                  :if={chat.source == :agent}
                  alt="Tailwind CSS chat bubble component"
                  src="https://i.pravatar.cc/150?u=random"
                  }
                />
              </div>
            </div>
            <div class="chat-header">
              {chat.sender_phone_number}
              <time class="text-xs opacity-50">{NaiveDateTime.to_time(chat.inserted_at)}</time>
            </div>
            <div class="chat-bubble">{chat.message}</div>
            <div class="chat-footer opacity-50">Delivered</div>
          </div>
        <% end %>
      </div>

      <div class="flex w-[65%] bg-gray-700 p-4 rounded-lg shadow-lg">
        <.simple_form
          for={@form}
          id="chat-form"
          phx-submit="send"
          class="grid grid-cols-[80%_20%] gap-2 w-full mt-0"
        >
          <.input
            phx-mounted={JS.focus()}
            field={@form[:message]}
            type="text"
            placeholder="Type a message..."
            class="w-full  border border-gray-500 bg-gray-800 text-white focus:ring-2 focus:ring-blue-500"
          />
          
          <:actions>
            <.button
              phx-disable-with="sending..."
              class="w-full mt-2 px-4 py-2 bg-blue-500 text-white hover:bg-blue-600 transition duration-300"
            >
              <.icon name="hero-paper-airplane" />
            </.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end
end
