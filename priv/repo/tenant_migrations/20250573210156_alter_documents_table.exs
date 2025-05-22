defmodule Flowmind.Repo.Migrations.UpdateEmbeddingVectorSize do
  use Ecto.Migration

  def change do
    alter table(:documents) do
      modify :embedding, :vector, size: 384
      modify :text, :text
    end
  end
end
