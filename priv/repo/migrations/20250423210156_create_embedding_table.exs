defmodule Flowmind.Repo.Migrations.CreateEmbeddingTable do
  use Ecto.Migration

  def change do
    create table(:items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :text, :string
      add :embedding, :vector

      timestamps(type: :utc_datetime)
    end
  end
end
