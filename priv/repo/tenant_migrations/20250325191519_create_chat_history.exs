defmodule Flowmind.Repo.Migrations.CreateChatHistory do
  use Ecto.Migration

  def change do
    create table(:chat_history, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :phone_number_id, :string
      add :whatsapp_id, :string
      add :ref_whatsapp_id, :string
      add :sender_phone_number, :string
      add :message, :text
      add :source, :string
      add :message_type, :string
      add :caption, :string
      add :delivered, :boolean, default: false, null: false
      add :readed, :boolean, default: false, null: false
      add :collected, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end
    
    create index(:chat_history, [:phone_number_id])
    create index(:chat_history, [:sender_phone_number])
    create index(:chat_history, [:whatsapp_id])
    create index(:chat_history, [:ref_whatsapp_id])
  end
end
