defmodule GameBackend.Repo.Migrations.BattleStats do
  use Ecto.Migration

  def change do
    create table(:skills) do
      add :name, :string
      add :effects, :map
      add :cooldown, :integer
      add :energy_regen, :integer
      add :animation_duration, :integer
      add :animation_trigger, :integer
      timestamps()
    end

    alter table :characters do
      add :basic_skill_id, references(:skills)
      add :ultimate_skill_id, references(:skills)

      add :base_health, :integer
      add :base_attack, :integer
      add :base_defense, :integer
    end
  end
end
