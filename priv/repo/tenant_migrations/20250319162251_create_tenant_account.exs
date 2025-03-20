defmodule Flowmind.Repo.Migrations.CreateTenantAccount do
  use Ecto.Migration

  def change do
    create table(:tenant_account, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :waba, :string
      add :config, :text

      timestamps(type: :utc_datetime)
    end
  end
end
