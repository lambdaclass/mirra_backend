defmodule GameBackend.Repo.Migrations.CreateMechanics do
  use Ecto.Migration

  def change do
    create table(:apply_effects_to) do
      add(:effects, :map)
      add(:targeting_strategy, :map)
    end

    create table(:passive_effects) do
      add(:effects, :map)
    end

    alter table(:skills) do
      remove(:effects)
    end

    create table(:mechanics) do
      add(:trigger_delay, :integer)
      add(:skill_id, references(:skills))
      add(:apply_effects_to_id, references(:apply_effects_to))
      add(:passive_effects_id, references(:passive_effects))
    end
  end
end
