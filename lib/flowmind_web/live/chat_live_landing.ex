defmodule FlowmindWeb.ChatLiveLanding do
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
    chat_inbox = Chat.list_chat_inbox()
    tenant = Flowmind.TenantGenServer.get_tenant()

    socket =
      socket
      |> assign(:sender_phone_number, nil)
      |> assign(:chat_history, [])
      |> assign(:chat_inbox, chat_inbox)
      |> assign(:tenant, tenant)
      |> assign(:tenant_accounts, [])

    {:ok, socket, layout: {FlowmindWeb.ChatLayouts, :app}}
  end



  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-[90vh]">
      

    </div>
    """
  end
end
