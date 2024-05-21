defmodule GameBackend.Repo.Migrations.AddCurrencyCostToLevels do
  use Ecto.Migration

  def change do
    alter table(:levels) do
      add(:attempt_cost, {:array, :map})
    end
  end
end
