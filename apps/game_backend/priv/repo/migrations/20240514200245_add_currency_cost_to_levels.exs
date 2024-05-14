defmodule GameBackend.Repo.Migrations.AddCurrencyCostToLevels do
  use Ecto.Migration

  def change do
    alter table(:levels) do
      add(:currency_costs, {:array, :map})
    end
  end
end
