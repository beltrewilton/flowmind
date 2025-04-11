defmodule FlowmindWeb.UserProfileLive do
  use FlowmindWeb, :live_view

  alias Flowmind.Accounts
  alias Flowmind.Organization

  def doc do
    "UserProfileLive"
  end

  @impl true
  def mount(params, _session, socket) do
    user_id = Map.get(params, "id")
    tenant = Flowmind.TenantGenServer.get_tenant()

    user = Accounts.get_user_by_id!(user_id)
    customers = Organization.list_customers

    socket =
      socket
      |> assign(:user, user)
      |> assign(:customers, customers)
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
      <h2>{@user.name}</h2>
    </div>
    
    <%= for customer <- @customers do %>
      <div  class="flex flex-row items-center space-x-4 p-2">
        <div>
          <.input id={"inputs-checkbox-#{customer.id}"} placeholder="Checkbox input" type="checkbox"/>
        </div>
        <a class="p-7 btn btn-ghost text-xl flex flex-col items-start">
          {customer.name}
          <.badge size="xs" class="-mt-2 -ml-1">
            <div class="w-4 h-4">
              <img
                src={"data:image/png;base64,#{CountryLookup.lookup_by_code(customer.phone_number).flag_image}"}
                alt="flag"
                class="w-full h-full object-contain"
              />
            </div>
            {customer.phone_number}
          </.badge>
        </a>
      </div>
    <% end %>
    """
  end
end
