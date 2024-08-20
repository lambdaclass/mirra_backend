defmodule GameBackend.Repo.Migrations.AddActivatedAtToUserQuests do
  use Ecto.Migration

  def change do
    alter table(:user_quests) do
      add(:activated_at, :utc_datetime)
    end
    alter table(:users) do
      add(:last_daily_quest_generation_at, :utc_datetime)
    end
  end
end
