defmodule Flowmind.Repo.Migrations.CreateEmployees do
  use Ecto.Migration

  def change do
    create table(:employees, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :job_title, :string
      add :department, :string
      add :status, :string
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing, prefix: "public")

      timestamps(type: :utc_datetime)
    end
  end
end
