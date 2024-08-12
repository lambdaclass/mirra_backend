defmodule GameBackend.Repo.Migrations.AlterTablesForEffectMigration do
  use Ecto.Migration

  def change do
    alter table(:consumable_items) do
      add :effect, :map
    end
    alter table(:mechanics) do
      add :effect, :map
    end
  end
end
