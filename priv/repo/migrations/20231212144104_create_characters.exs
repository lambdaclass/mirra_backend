defmodule DarkWorldsServer.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add :name, :string
      add :active, :boolean, default: false, null: false
      add :base_speed, :integer
      add :base_size, :integer
      add :base_health, :integer
      add :max_inventory_size, :integer
      timestamps()
    end

    create table(:skills) do
      add :name, :string
      add :cooldown_ms, :integer
      add :execution_duration_ms, :integer
      add :is_passive, :boolean, default: false, null: false
      add :mechanics, {:array, :string} # SkillMechanic
      timestamps()
    end

    create table(:character_skills) do
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      add :skill_id, references(:skills, on_delete: :delete_all), null: false
      add :skill_number, :integer
      timestamps()
    end

    create table(:effects) do
      add :name, :string
      add :is_reversable, :boolean, default: false, null: false
      add :effect_time_type, :string
      add :player_attributes, :map
      add :projectile_attributes, :map
      add :skills_keys_to_execute, {:array, :string}
      timestamps()
    end

    create unique_index(:characters, :name)
    create unique_index(:skills, :name)
    create unique_index(:effects, :name)
  end
end
