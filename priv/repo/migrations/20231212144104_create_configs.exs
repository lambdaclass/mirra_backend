defmodule DarkWorldsServer.Repo.Migrations.CreateConfigs do
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

    create table(:projectiles) do
      add :name, :string
      add :base_damage, :integer
      add :base_speed, :integer
      add :base_size, :integer
      add :duration_ms, :integer
      add :max_distance, :integer
      add :remove_on_collision, :boolean, default: false, null: false
      timestamps()
    end

    create table(:projectile_effects) do
      add :projectile_id, references(:projectiles, on_delete: :delete_all), null: false
      add :effect_id, references(:effects, on_delete: :delete_all), null: false
      timestamps()
    end

    create table(:loots) do
      add :name, :string
      add :size, :integer
      add :pickup_mechanic, :string
      timestamps()
    end

    create table(:loot_effects) do
      add :loot_id, references(:loots, on_delete: :delete_all), null: false
      add :effect_id, references(:effects, on_delete: :delete_all), null: false
      timestamps()
    end

    create table(:games) do
      add :width, :integer
      add :height, :integer
      add :loot_interval_ms, :integer
      add :zone_starting_radius, :integer
      add :auto_aim_max_distance, :float
      add :initial_positions, {:array, :map}
      timestamps()
    end

    create table(:zone_modifications) do
      add :duration_ms, :integer
      add :interval_ms, :integer
      add :min_radius, :integer
      add :max_radius, :integer
      add :modifier, :string
      add :value, :float
      add :effect_names, {:array, :string}

      add :game_id, references(:games, on_delete: :delete_all), null: false
      timestamps()
    end

    create table(:zone_effects) do
      add :zone_modification_id, references(:zone_modifications, on_delete: :delete_all), null: false
      add :effect_id, references(:effects, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:characters, :name)
    create unique_index(:skills, :name)
    create unique_index(:effects, :name)
    create unique_index(:projectiles, :name)
    create unique_index(:loots, :name)
    create unique_index(:character_skills, [:character_id, :skill_number])
  end
end
