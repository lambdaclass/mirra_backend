defmodule GameBackend.Repo.Migrations.RenameDailyquestToUserquest do
  use Ecto.Migration

  def change do
    rename table(:daily_quest), to: table(:user_quests)
  end
end
