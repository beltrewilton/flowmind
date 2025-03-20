defmodule FlowmindWeb.UserRegistrationLive do
  use FlowmindWeb, :live_view

  alias Flowmind.Accounts
  alias Flowmind.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Register for an account
        <:subtitle>
          Already registered?
          <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
            Log in
          </.link>
          to your account now.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=registered"}
        method="post"
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.inputs_for :let={company} field={@form[:company]}>
          <.input field={company[:company_name]} type="text" label="Company Name" required />
          <.input field={company[:tenant]} type="text" label="Tenant" required />
        </.inputs_for>

        <hr />
        <.input field={@form[:name]} type="text" label="Name" required />
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full">Create an account</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user_changeset = Accounts.user_company_changeset(%User{})
    {:ok, assign_form(socket, user_changeset)}

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(user_changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user_company" => user_company_params}, socket) do
    case Accounts.create_company(user_company_params["company"]) do
      {:ok, company} ->
        user_company_params = Map.put(user_company_params, "company_id", company.id)
        Triplex.create(user_company_params["company"]["tenant"])
        insert_user(user_company_params, socket)

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user_company" => user_company_params}, socket) do
    changeset = Accounts.user_company_changeset(%User{}, user_company_params)

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end
  
  defp insert_user(user_company_params, socket) do
    case Accounts.register_user(user_company_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.user_company_changeset(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user_company")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
