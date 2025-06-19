defmodule Flowmind.Repo.Migrations.CreateWebLogs do
  use Ecto.Migration

  def change do
    create table(:webhook_log, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :source, :string
      add :response, :map
      add :waba_id, :string

      timestamps(type: :utc_datetime)
    end

    create index(:webhook_log, [:waba_id])
  end
end
