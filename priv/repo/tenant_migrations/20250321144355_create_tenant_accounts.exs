defmodule Flowmind.Repo.Migrations.CreateTenantAccounts do
  use Ecto.Migration

  def change do
    create table(:tenant_accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :phone_number_id, :string
      add :waba_id, :string
      add :token_exchange_code, :text
      add :access_token, :text
      add :subscribed_apps_response, :map
      add :register_ph_response, :map
      add :active, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end
    
    create index(:tenant_accounts, [:phone_number_id])
    create index(:tenant_accounts, [:waba_id])
  end
end
