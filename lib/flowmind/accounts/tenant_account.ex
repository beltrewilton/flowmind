defmodule Flowmind.Accounts.TenantAccount do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tenant_accounts" do
    field :active, :boolean, default: false
    field :connected, :boolean, default: false
    field :phone_number_id, :string
    field :waba_id, :string
    field :token_exchange_code, :string
    field :access_token, :string
    field :subscribed_apps_response, :map
    field :register_ph_response, :map
    field :code_verification_status, :string
    field :display_phone_number, :string
    field :platform_type, :string
    field :quality_rating, :string
    field :status, :string
    field :verified_name, :string

    timestamps(type: :utc_datetime)
  end

  def compute_connected(account) do
    account.subscribed_apps_response["success"] == true and
      account.register_ph_response["success"] == true
  end

  @doc false
  def changeset(tenant_account, attrs) do
    tenant_account
    |> cast(attrs, [
      :phone_number_id,
      :waba_id,
      :token_exchange_code,
      :access_token,
      :subscribed_apps_response,
      :register_ph_response,
      :active,
      :connected,
      :code_verification_status,
      :display_phone_number,
      :platform_type,
      :quality_rating,
      :status,
      :verified_name
    ])
    |> validate_required([:phone_number_id, :waba_id])
  end
end
