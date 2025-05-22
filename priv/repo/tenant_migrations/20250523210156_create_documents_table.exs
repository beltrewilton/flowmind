defmodule Flowmind.Repo.Migrations.CreateDocumentsTable do
  use Ecto.Migration

  def change do
    create table(:documents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :text, :string
      add :embedding, :vector, size: 768
      
      timestamps(type: :utc_datetime)
    end
  end
end
