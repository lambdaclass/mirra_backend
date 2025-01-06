defmodule GameBackend.Repo.Migrations.UpdateSkillsUniqueIndex do
  use Ecto.Migration

  def change do
    drop unique_index(:skills, [:name])
    drop unique_index(:skills, [:game_id, :name])
    drop unique_index(:characters, [:game_id, :name])
    create unique_index(:characters, [:game_id, :name, :version_id])

    create unique_index(:skills, [:game_id, :name, :version_id])
  end
end
