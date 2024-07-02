defmodule Configurator.Repo.Migrations.AlterSkillsForCongfi do
  use Ecto.Migration

  def change do
    alter table(:skills) do
      add :game_id, :integer
      add :activation_delay_ms, :integer
      add :autoaim, :boolean, default: false, null: false
      add :block_movement, :boolean, default: false, null: false
      add :can_pick_destination, :boolean, default: false, null: false
      add :cooldown_mechanism, :string
      add :cooldown_ms, :integer
      add :execution_duration_ms, :integer
      add :inmune_while_executing, :boolean, default: false, null: false
      add :is_passive, :boolean, default: false, null: false
      add :max_autoaim_range, :integer
      add :stamina_cost, :integer
    end

    create unique_index(:skills, [:game_id, :name])

    alter table(:mechanics) do
      add :type, :string
      add :amount, :integer
      add :angle_between, :decimal
      add :damage, :integer
      add :duration_ms, :integer
      add :effects_to_apply, {:array, :string}
      add :interval_ms, :integer
      add :move_by, :decimal
      add :name, :string
      add :offset, :integer
      add :projectile_offset, :integer
      add :radius, :decimal
      add :range, :decimal
      add :remove_on_collision, :boolean, default: false, null: false
      add :speed, :decimal
      add :on_arrival_mechanic_id, references(:mechanics, on_delete: :nothing)
      add :on_explode_mechanic_id, references(:mechanics, on_delete: :nothing)
    end

    create index(:mechanics, [:on_arrival_mechanic_id])
    create index(:mechanics, [:on_explode_mechanic_id])

    alter table :characters do
      remove :skills
      add :dash_skill_id, references(:skills, on_delete: :delete_all)
    end
  end
end
