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

    {:noreply, socket}
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "entry_form"))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-5 w-full">
      <h2>{@user.name}</h2>
    </div>

    <.simple_form
      for={@form}
      id="customer-list-form"
      phx-submit="send"
      class=""
    >
    <%= for customer <- @customers do %>
      <div  class="flex flex-row items-center space-x-4 p-2">
        <div>
          <.input name="entry_form[customer_ids][]" value={customer.id} checked={!!customer.checked}  id={"inputs-checkbox-#{customer.id}"} placeholder="Checkbox input" type="checkbox"/>
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
    <:actions>
      <.button
        id="send-customer-button-id"
        phx-disable-with="sending..."
        class="w-full mt-2 px-4 py-2 bg-blue-500 text-white hover:bg-blue-600 transition duration-300"
      >
        <.icon name="hero-paper-airplane" />
      </.button>
    </:actions>
    </.simple_form>
    """
  end
end
