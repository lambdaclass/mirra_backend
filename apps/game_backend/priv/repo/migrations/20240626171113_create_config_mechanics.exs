defmodule Configurator.Repo.Migrations.CreateConfigMechanics do
  use Ecto.Migration

  def change do
    create table(:config_mechanics) do
      add :type, :string, null: false
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
      add :on_arrival_mechanic_id, references(:config_mechanics, on_delete: :nothing)
      add :on_explode_mechanic_id, references(:config_mechanics, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:config_mechanics, [:on_arrival_mechanic_id])
    create index(:config_mechanics, [:on_explode_mechanic_id])
  end
end
