defmodule GameBackend.Repo.Migrations.BattleStats do
  use Ecto.Migration

  def change do
    create table(:skills) do
      add :name, :string
      add :effects, :map
      add :cooldown, :integer
      add :targeting_strategy, :string
      add :targets_allies, :bool
      add :amount_of_targets, :integer
      timestamps()
    end

    alter table :characters do
      add :basic_skill_id, references(:skills)
      add :ultimate_skill_id, references(:skills)

      add :base_health, :integer
      add :base_attack, :integer
      add :base_armor, :integer
    end

    create unique_index(:skills, [:name])
  end
end
