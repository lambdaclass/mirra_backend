defmodule GameBackend.Repo.Migrations.AddStatusToDailyQuest do
  use Ecto.Migration

  def change do
    alter table(:daily_quest) do
      add :status, :string, default: "available", null: false
    end
  end
end
