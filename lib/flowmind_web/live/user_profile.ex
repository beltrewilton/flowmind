defmodule FlowmindWeb.UserProfileLive do
  use FlowmindWeb, :live_view

  alias Flowmind.Accounts
  alias Flowmind.Organization
  alias Flowmind.Organization.Customer

  def doc do
    "UserProfileLive"
  end

  @impl true
  def mount(params, _session, socket) do
    user_id = Map.get(params, "id")
    tenant = Flowmind.TenantContext.get_tenant()

    user = Accounts.get_user!(user_id)
    customers = Organization.list_customers_with_check(user)

    form_source = Organization.change_customer(%Customer{})

    socket =
      socket
      |> assign(:user, user)
      |> assign(:customers, customers)
      |> assign(:tenant, tenant)
      |> assign(:tenant_accounts, [])
      |> assign_form(form_source)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("send", entry_form, socket) do
    user = socket.assigns.user
    entry_form = Map.get(entry_form, "entry_form")
    IO.inspect(entry_form, label: "entry_form")

    customers =
      if !is_nil(entry_form),
        do: entry_form["customer_ids"] |> Enum.map(&Organization.get_customer!/1),
        else: []

    Accounts.update_user_customers(user, customers)

    user = Accounts.get_user!(user.id)
    customers = Organization.list_customers_with_check(user)

    socket =
      socket
      |> assign(:user, user)
      |> assign(:customers, customers)
      |> put_flash(:info, "It worked!")
      |> push_navigate(to: ~p"/userlist")

    {:noreply, socket}
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "entry_form"))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.breadcrumbs class="pl-5">
      <:item icon="hero-users"><.link patch={~p"/userlist"}>Users</.link></:item>
      <:item >List of assigns customers</:item>
    </.breadcrumbs>
    
    <div class="p-5">
      <.simple_form
        for={@form}
        id="customer-list-form"
        phx-submit="send"
        class=""
      >
      <div class="flex col-2">
        <.avatar class="mb-1">
          <div class="mask mask-squircle w-16">
            <img src={"https://i.pravatar.cc/150?u=#{@user.id}"} />
          </div>
        </.avatar>
        <div class="pl-5">
          <h2>{@user.name}</h2>
          <h2>{@user.email}</h2>
        </div>
      </div>
      <div class="divider"></div>
      <div>Customer List</div>
      <%= for customer <- @customers do %>
        <.list class="hover:bg-gray-200 cursor-pointer transition duration-300">
          <:item >
            <div><img class="size-10 rounded-box" src={"https://i.pravatar.cc/150?u=#{customer.phone_number}"}/></div>
            <div>
              <div>{customer.name}</div>
              <div class="text-xs uppercase font-semibold opacity-60">
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
              </div>
            </div>
            <.button shape="square" ghost>
              <.input name="entry_form[customer_ids][]" value={customer.id} checked={!!customer.checked}  id={"inputs-checkbox-#{customer.id}"} placeholder="Checkbox input" type="checkbox"/>
            </.button>
          </:item>
        </.list>
      <% end %>
      <:actions>
       
        
        <div class="flex justify-end w-full">
          <.button  
            id="send-customer-button-id"
            phx-disable-with="saving..." color="primary" class="w-1/4 mt-4 hover:bg-blue-600 transition duration-300">
            Save assigns
            <.icon name="hero-cloud-arrow-up" />
          </.button>
        </div>
      </:actions>
      </.simple_form>
    </div>
    """
  end
end
