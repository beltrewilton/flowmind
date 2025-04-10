defmodule Flowmind.Repo.Migrations.CreateCustomers do
  use Ecto.Migration

  def change do
    create table(:customers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :phone_number, :string
      add :name, :string
      add :email, :string
      add :avatar, :string
      add :status, :string
      add :document_id, :string
      add :note, :text
      add :extra_fields, :map
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing, prefix: "public")

      timestamps(type: :utc_datetime)
    end
    
    create index(:customers, [:phone_number, :user_id])
  end
end
