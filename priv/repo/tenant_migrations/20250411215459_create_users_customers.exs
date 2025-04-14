defmodule Flowmind.Repo.Migrations.CreateUsersCustomersJoinTable do
  use Ecto.Migration

  def change do
    create table(:users_customers, primary_key: false) do
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all, prefix: "public")
      add :customer_id, references(:customers, type: :binary_id, on_delete: :delete_all)

      # timestamps(type: :utc_datetime)
    end

    create unique_index(:users_customers, [:user_id, :customer_id])
  end
end
