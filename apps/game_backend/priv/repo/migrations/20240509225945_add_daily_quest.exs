defmodule GameBackend.Repo.Migrations.AddDailyQuest do
  use Ecto.Migration

  def change do
    create table(:daily_quest) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :quest_id, references(:quests, on_delete: :delete_all), null: false
      add :completed_at, :utc_datetime
      timestamps()
    end
  end
end
