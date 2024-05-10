defmodule GameBackend.Repo.Migrations.AddUserDailyQuest do
  use Ecto.Migration

  def change do
    create table(:user_daily_quest) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :quest_description_id, references(:quest_descriptions, on_delete: :delete_all), null: false
      add :target, :integer
      add :progress, :integer
      timestamps()
    end
  end
end
