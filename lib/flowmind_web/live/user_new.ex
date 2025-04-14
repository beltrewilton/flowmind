defmodule FlowmindWeb.UserNewLive do
  use FlowmindWeb, :live_view
  alias Flowmind.Accounts
  alias Flowmind.Accounts.User
  
  def doc do
    "UserNewLive"
  end

  @impl true
  def mount(_params, _session, socket) do
    tenant = Flowmind.TenantContext.get_tenant()
  
    user_changeset = Accounts.user_company_changeset(%User{})
    
    socket =
      socket
      |> assign(:tenant, tenant)
      |> assign(:tenant_accounts, [])
      |> assign_form(user_changeset)
    {:ok, socket}
  end
  
  def handle_event("send", entry_form, socket) do
    current_user = socket.assigns.current_user
    entry_form = Map.get(entry_form, "entry_form")
    entry_form = entry_form |> Map.put("role", :employee)
    IO.inspect(entry_form, label: "entry_form")
    
    {:ok, user} = Accounts.register_user(entry_form)
    Accounts.update_user_company(user, current_user.company)
    
    {:ok, _} =
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    
    socket =
      socket
      |> push_navigate(to: ~p"/userprofile/#{user.id}")

    {:noreply, socket}
  end
  
  def handle_event("validate", %{"entry_form" => entry_form}, socket) do
    changeset = Accounts.change_user_registration(%User{}, entry_form)

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end
  
  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
  
  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "entry_form"))
  end

  @impl true
  def render(assigns) do
    ~H"""
    User new
    <div class="flex flex-col items-center gap-5 w-full">
      <.simple_form
        for={@form}
        id="user-new-form"
        phx-submit="send"
        phx-change="validate"
        class=""
      >
        <.fieldset class="w-full p-5">
          <.fieldset_label>Name</.fieldset_label>
          <.input field={@form[:name]} type="text" placeholder="Name" required />
          <.fieldset_label>Email</.fieldset_label>
          <.input field={@form[:email]} type="email" placeholder="Email" required />
          <.fieldset_label>Password</.fieldset_label>
          <.input field={@form[:password]} type="password" placeholder="Password" required />
        </.fieldset>
        <:actions>
          <.button class="btn btn-primary mt-4">Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
