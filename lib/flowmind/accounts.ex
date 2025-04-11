defmodule Flowmind.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset
  alias Flowmind.Repo

  alias Flowmind.Accounts.{User, UserToken, UserNotifier}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def get_users_by_company(company_id) do
    from(u in User,
      where: u.company_id == ^company_id,
      preload: [:company]
    )
    |> Repo.all()
  end
  
  def get_user_by_id!(id) do
    from(u in User,
      where: u.id == ^id,
      preload: [:company]
    )
    |> Repo.one!()
  end

  alias Flowmind.Accounts.Company

  @doc """
  Returns the list of company.

  ## Examples

      iex> list_company()
      [%Company{}, ...]

  """
  def list_company do
    Repo.all(Company)
  end

  @doc """
  Gets a single company.

  Raises `Ecto.NoResultsError` if the Company does not exist.

  ## Examples

      iex> get_company!(123)
      %Company{}

      iex> get_company!(456)
      ** (Ecto.NoResultsError)

  """
  def get_company!(id), do: Repo.get!(Company, id)

  @doc """
  Creates a company.

  ## Examples

      iex> create_company(%{field: value})
      {:ok, %Company{}}

      iex> create_company(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_company(attrs \\ %{}) do
    %Company{}
    |> Company.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a company.

  ## Examples

      iex> update_company(company, %{field: new_value})
      {:ok, %Company{}}

      iex> update_company(company, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_company(%Company{} = company, attrs) do
    company
    |> Company.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a company.

  ## Examples

      iex> delete_company(company)
      {:ok, %Company{}}

      iex> delete_company(company)
      {:error, %Ecto.Changeset{}}

  """
  def delete_company(%Company{} = company) do
    Repo.delete(company)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking company changes.

  ## Examples

      iex> change_company(company)
      %Ecto.Changeset{data: %Company{}}

  """
  def change_company(%Company{} = company, attrs \\ %{}) do
    Company.changeset(company, attrs)
  end

  def user_company_changeset(%User{} = user, attrs \\ %{}) do
    user
    |> Repo.preload(:company)
    |> change_user_registration(attrs)
    |> cast_assoc(:company, with: &change_company/2)
  end

  alias Flowmind.Accounts.TenantAccount

  @doc """
  Returns the list of tenant_accounts.

  ## Examples

      iex> list_tenant_accounts()
      [%TenantAccount{}, ...]

  """
  def list_tenant_accounts do
    tenant = Flowmind.TenantGenServer.get_tenant()
    Repo.all(TenantAccount, prefix: tenant)
  end

  @doc """
  Gets a single tenant_account.

  Raises `Ecto.NoResultsError` if the Tenant account does not exist.

  ## Examples

      iex> get_tenant_account!(123)
      %TenantAccount{}

      iex> get_tenant_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tenant_account!(id) do
    tenant = Flowmind.TenantGenServer.get_tenant()
    Repo.get!(TenantAccount, id, prefix: tenant)
  end

  @doc """
  Creates a tenant_account.

  ## Examples

      iex> create_tenant_account(%{field: value})
      {:ok, %TenantAccount{}}

      iex> create_tenant_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tenant_account(attrs \\ %{}) do
    tenant = Flowmind.TenantGenServer.get_tenant()

    %TenantAccount{}
    |> TenantAccount.changeset(attrs)
    |> Repo.insert(prefix: tenant)
  end

  @doc """
  Updates a tenant_account.

  ## Examples

      iex> update_tenant_account(tenant_account, %{field: new_value})
      {:ok, %TenantAccount{}}

      iex> update_tenant_account(tenant_account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tenant_account(%TenantAccount{} = tenant_account, attrs) do
    tenant = Flowmind.TenantGenServer.get_tenant()

    tenant_account
    |> TenantAccount.changeset(attrs)
    |> Repo.update(prefix: tenant)
  end

  @doc """
  Deletes a tenant_account.

  ## Examples

      iex> delete_tenant_account(tenant_account)
      {:ok, %TenantAccount{}}

      iex> delete_tenant_account(tenant_account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tenant_account(%TenantAccount{} = tenant_account) do
    Repo.delete(tenant_account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tenant_account changes.

  ## Examples

      iex> change_tenant_account(tenant_account)
      %Ecto.Changeset{data: %TenantAccount{}}

  """
  def change_tenant_account(%TenantAccount{} = tenant_account, attrs \\ %{}) do
    TenantAccount.changeset(tenant_account, attrs)
  end

  def insert_tenant_account(attrs, tenant) do
    %TenantAccount{}
    |> TenantAccount.changeset(attrs)
    |> Repo.insert(prefix: tenant)
  end

  def mocked_data(tenant) do
    # Insert multiple demo tenant accounts
    [
      %{
        active: true,
        phone_number_id: "606765489182594",
        waba_id: "443834038808808",
        token_exchange_code: "AQ1234xyz...",
        access_token: "mocked_access_token",
        subscribed_apps_response: %{"success" => true},
        register_ph_response: %{"success" => true},
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        code_verification_status: "VERIFIED",
        display_phone_number: "+1 849-657-7713",
        platform_type: "CLOUD_API",
        quality_rating: "UNKNOWN",
        status: "CONNECTED",
        verified_name: "Ceidi TEST"
      },
      %{
        active: false,
        phone_number_id: "441214785740868",
        waba_id: "443834038808808",
        token_exchange_code: "BQ5678xyz...",
        access_token: "mocked_access_token",
        subscribed_apps_response: %{"success" => false},
        register_ph_response: %{"success" => true},
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        code_verification_status: "EXPIRED",
        display_phone_number: "+1 849-650-8622",
        platform_type: "CLOUD_API",
        quality_rating: "GREEN",
        status: "CONNECTED",
        verified_name: "Ceidi - Agente Virtual"
      }
    ]
    |> Enum.each(&insert_tenant_account(&1, tenant))

    IO.puts("✅ Demo data loaded successfully!")
  end
end
