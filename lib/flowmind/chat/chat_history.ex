defmodule Flowmind.Chat.ChatHistory do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "chat_history" do
    field :message, :string
    field :phone_number_id, :string
    field :whatsapp_id, :string
    field :readed, :boolean, default: false
    field :collected, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chat_history, attrs) do
    chat_history
    |> cast(attrs, [:phone_number_id, :whatsapp_id, :message, :readed, :collected])
    |> validate_required([:phone_number_id, :message])
  end
end
