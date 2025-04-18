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
    <.breadcrumbs class="pl-5">
      <:item icon="hero-users">Users</:item>
    </.breadcrumbs>
    
    <div class="flex col-1 mb-0 p-5">
      <div class="text-xl w-1/2">User List</div>
      <div class="flex justify-end w-full"><.link patch={~p"/usernew"} class="btn btn-primary hover:decoration-none">New User</.link></div>
    </div>
    <div class="h-[70vh] overflow-y-auto">
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 p-5">
    <%= for user <- @users do%>
      <.card class="bg-base-200 shadow-lg place-items-center">
        <figure class="h-1/2">
          <.avatar class="mb-1 absolute">
            <div class="mask mask-squircle w-16">
              <.link href={"/userprofile/#{user.id}"} >
                <img src={"https://i.pravatar.cc/150?u=#{user.id}"} class="transition transform hover:scale-110"/>
              </.link>
            </div>
          </.avatar>
          <img 
            src="/images/54041.jpg"
            alt="" />
        </figure>
        
        <:card_body class="pt-0 place-items-center">
          <div>{user.name}</div>
          <div>{user.email}</div>
        </:card_body>
        
      </.card>
      <% end %>
    </div>
    </div>
    """
  end
end
