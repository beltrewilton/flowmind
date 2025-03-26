defmodule Flowmind.Repo.Migrations.CreateChatHistory do
  use Ecto.Migration

  def change do
    create table(:chat_history, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :phone_number_id, :string
      add :whatsapp_id, :string
      add :sender_phone_number, :string
      add :message, :text
      add :readed, :boolean, default: false, null: false
      add :collected, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end
    
    create index(:chat_history, [:phone_number_id])
    create index(:chat_history, [:sender_phone_number])
  end
end
