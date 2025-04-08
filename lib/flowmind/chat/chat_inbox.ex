defmodule Flowmind.Chat.ChatInbox do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "chat_inbox" do
    field :seed, :string
    field :phone_number_id, :string
    field :sender_phone_number, :string
    field :alias, :string
    field :readed, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chat_inbox, attrs) do
    chat_inbox
    |> cast(attrs, [:seed, :phone_number_id, :sender_phone_number, :alias, :readed])
    |> validate_required([:phone_number_id, :sender_phone_number])
  end
end
