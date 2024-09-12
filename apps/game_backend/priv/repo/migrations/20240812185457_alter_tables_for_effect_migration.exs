defmodule GameBackend.Repo.Migrations.AlterTablesForEffectMigration do
  use Ecto.Migration

  def change do
    alter table(:consumable_items) do
      add :effect, :map
    end
    alter table(:mechanics) do
      add :effect, :map
      remove :effects_to_apply
    end

    alter table(:skills) do
      add :effect_to_apply, :map
      remove :effects_to_apply
    end
  end
end
