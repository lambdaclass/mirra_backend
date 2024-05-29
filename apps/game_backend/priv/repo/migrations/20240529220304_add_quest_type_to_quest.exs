defmodule GameBackend.Repo.Migrations.AddQuestTypeToQuest do
  use Ecto.Migration

  def change do
    alter table(:quests) do
      add :quest_type, :string, null: true
    end
  end
end
