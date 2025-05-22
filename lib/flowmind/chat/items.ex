defmodule Flowmind.Chat.Item do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "items" do
    field :text, :string
    field :embedding, Pgvector.Ecto.Vector

    # timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(items, attrs) do
    items
    |> cast(attrs, [:text, :embedding])
  end
end
