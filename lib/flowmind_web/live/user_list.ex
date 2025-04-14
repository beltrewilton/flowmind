defmodule FlowmindWeb.UserListLive do
  use FlowmindWeb, :live_view

  alias Flowmind.Accounts

  def doc do
    "UserListLive"
  end

  @impl true
  def mount(_params, _session, socket) do
    tenant = Flowmind.TenantContext.get_tenant()
    current_user = socket.assigns.current_user
    users = Accounts.get_users_by_company(current_user.company_id)

    socket =
      socket
      |> assign(:users, users)
      |> assign(:tenant, tenant)
      |> assign(:tenant_accounts, [])

    {:ok, socket}
  end
  
  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-5 w-full">
      <.table id="users-id" rows={@users}>
        <:col :let={user} label="name">
          <.link href={"/userprofile/#{user.id}"}>{user.name}</.link>
        </:col>
        <:col :let={user} label="role">{user.role}</:col>
        <:col :let={user} label="email">{user.email}</:col>
      </.table>
    </div>
    """
  end
end
