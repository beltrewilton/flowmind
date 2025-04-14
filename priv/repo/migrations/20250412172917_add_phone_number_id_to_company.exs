defmodule Flowmind.Repo.Migrations.AddPhoneNumberIdToCompany do
  use Ecto.Migration

  def change do
    alter table(:company) do
      add :phone_number_id, :string
    end

    create index(:company, [:phone_number_id])
  end
end
