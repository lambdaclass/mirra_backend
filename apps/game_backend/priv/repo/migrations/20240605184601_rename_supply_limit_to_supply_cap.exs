defmodule GameBackend.Repo.Migrations.RenameSupplyLimitToSupplyCap do
  use Ecto.Migration

  def change do
    alter table(:dungeon_settlement_levels) do
      remove :supply_limit
      add :supply_cap, :integer
    end
  end
end
