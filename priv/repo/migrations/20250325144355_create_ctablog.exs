defmodule Flowmind.Repo.Migrations.CTAWebLogs do
  use Ecto.Migration

  def change do
    create table(:cta_log, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :referer, :string
      add :user_agent, :string
      add :campaign, :string
      add :waba_id, :string

      timestamps(type: :utc_datetime)
    end

    create index(:cta_log, [:waba_id])
  end
end
