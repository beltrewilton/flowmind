defmodule Flowmind.Repo.Migrations.CreateChatInbox do
  use Ecto.Migration

  def change do
    create table(:chat_inbox, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :phone_number_id, :string
      add :sender_phone_number, :string

      timestamps(type: :utc_datetime)
    end
    
    create index(:chat_inbox, [:phone_number_id])
    create index(:chat_inbox, [:sender_phone_number])
  end
end
