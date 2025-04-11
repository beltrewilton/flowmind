defmodule FlowmindWeb.ChatLiveLanding do
  use FlowmindWeb, :live_view

  alias Flowmind.Chat
  alias Phoenix.PubSub
  alias Flowmind.Chat.ChatHistory
  alias FlowmindWeb.ChatPubsub
  alias FlowmindWeb.ChatLiveHelper

  def doc do
    "Chat"
  end

  @impl true
  def mount(params, _session, socket) do
    chat_inbox = Chat.list_chat_inbox()
    tenant = Flowmind.TenantGenServer.get_tenant()
    phone_number_id = Map.get(params, "phone_number_id")
    IO.inspect(phone_number_id, label: "phone_number_id")

    if connected?(socket), do: ChatPubsub.subscribe(phone_number_id)

    socket =
      socket
      |> assign(:phone_number_id, phone_number_id)
      |> assign(:sender_phone_number, nil)
      |> assign(:chat_history, [])
      |> assign(:chat_inbox, chat_inbox)
      |> assign(:tenant, tenant)
      |> assign(:tenant_accounts, [])
      |> assign(:edit_alias, false)
      |> assign(:alias_name, nil)

    {:ok, socket, layout: {FlowmindWeb.ChatLayouts, :app}}
  end

  @impl true
  def handle_info({:refresh_inbox, message}, socket) do
    ChatLiveHelper.refresh_inbox(message, socket)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-[90vh]">


    </div>
    """
  end
end
