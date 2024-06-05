defmodule GameBackend.Repo.Migrations.AddPurchaseCostsMapToItemTemplates do
  use Ecto.Migration

  def change do
    alter table(:item_templates) do
      add :purchase_costs, {:array, :map}
    end
  end
end
