defmodule YourApp.Repo.Migrations.AddPreferenceToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :preference, :map
    end
  end
end
