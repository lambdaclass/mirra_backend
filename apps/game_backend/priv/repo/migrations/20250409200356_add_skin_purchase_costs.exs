defmodule GameBackend.Repo.Migrations.AddSkinPurchaseCosts do
  use Ecto.Migration

  def change do
    alter table(:skins) do
      add :purchase_costs, {:array, :map}
    end
  end
end
