defmodule GameBackend.Repo.Migrations.BattleStats do
  use Ecto.Migration

  def change do
    create table(:skills) do
      add :effects, :map
      add :cooldown, :integer
      timestamps()
    end

    alter table :characters do
      add :basic_skill_id, references(:skills)
      add :ultimate_skill_id, references(:skills)

      add :base_health, :integer
      add :base_attack, :integer
      add :base_armor, :integer
    end
  end
end
