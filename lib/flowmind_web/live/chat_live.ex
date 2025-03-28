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

    chat_history = Chat.list_chat_history(sender_phone_number)

    chat_inbox = Chat.list_chat_inbox()

    form_source = Chat.change_chat_history(%ChatHistory{})
    
    tenant = Flowmind.TenantGenServer.get_tenant()

    socket =
      socket
      |> assign(:chat_history, chat_history)
      |> assign(:chat_inbox, chat_inbox)
      |> assign(:tenant, tenant)
      |> assign(:tenant_accounts, [])
      |> assign(:sender_phone_number, sender_phone_number)
      |> assign_form(form_source)

    {:ok, socket, layout: {FlowmindWeb.ChatLayouts, :app}}
  end

  @impl true
  def handle_event("send", %{"chat_history_form" => chat_history_form}, socket) do
    IO.inspect(chat_history_form, label: "chat_history_form")
    sender_phone_number = socket.assigns.sender_phone_number

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
    {:noreply, assign(socket, chat_history: chat_history)}
  end

  def handle_params(params, _uri, socket) do
    sender_phone_number = params["sender_phone_number"]
    old_sender_phone_number = socket.assigns.sender_phone_number
    
    IO.inspect(DateTime.utc_now(), label: "DateTime.utc_now()")
    IO.inspect(sender_phone_number, label: "sender_phone_number")
    IO.inspect(old_sender_phone_number, label: "old_sender_phone_number")
     
    if connected?(socket) do
      ChatPubsub.unsubscribe(old_sender_phone_number)
      ChatPubsub.subscribe(sender_phone_number)
    end

    chat_history = Chat.list_chat_history(sender_phone_number)

    socket =
      socket
      |> assign(:chat_history, chat_history)
      |> assign(:sender_phone_number, sender_phone_number)

    {:noreply, socket}
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "chat_history_form"))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.table id="chats" rows={@chat_history}>
      <:col :let={chat} label="phone_number_id">{chat.phone_number_id}</:col>
      <:col :let={chat} label="whatsapp_id">{chat.whatsapp_id}</:col>
      <:col :let={chat} label="message">{chat.message}</:col>
      <:col :let={chat} label="readed">{chat.readed}</:col>
      <:col :let={chat} label="collected">{chat.collected}</:col>
    </.table>

    <div class="flex flex-col items-center gap-5 w-full">
      <.simple_form for={@form} id="chat-form" phx-submit="send">
        <.input field={@form[:phone_number_id]} type="text" label="Phone Number" />
        <.input field={@form[:message]} type="text" label="Message" />
        <:actions>
          <.button phx-disable-with="sending...">send</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
