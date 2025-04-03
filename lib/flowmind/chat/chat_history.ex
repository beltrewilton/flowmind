defmodule Flowmind.Chat.ChatHistory do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "chat_history" do
    field :message, :string
    field :source, Ecto.Enum, values: [:user, :ai, :agent], default: :user
    field :phone_number_id, :string
    field :whatsapp_id, :string
    field :sender_phone_number, :string
    field :message_type, :string, default: "text"
    field :caption, :string
    field :delivered, :boolean, default: false
    field :readed, :boolean, default: false
    field :collected, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chat_history, attrs) do
    chat_history
    |> cast(attrs, [
      :phone_number_id,
      :whatsapp_id,
      :sender_phone_number,
      :message,
      :source,
      :delivered,
      :readed,
      :message_type,
      :caption,
      :collected
    ])
    |> validate_required([:message, :sender_phone_number])
  end
end
