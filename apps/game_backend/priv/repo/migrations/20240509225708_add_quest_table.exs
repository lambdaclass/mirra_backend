defmodule GameBackend.Repo.Migrations.AddQuestTable do
  use Ecto.Migration

  def change do
    create table(:quests) do
      add :description, :string, default: ""
      add :type, :string
      add :target, :integer
      add :quest_objectives, {:array, :map}
      timestamps()
    end
  end
end
