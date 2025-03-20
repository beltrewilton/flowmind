defmodule Flowmind.Repo.Migrations.CreateCompany do
  use Ecto.Migration

  def change do
    create table(:company, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :company_name, :string
      add :tenant, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:company, [:tenant])
  end
end
