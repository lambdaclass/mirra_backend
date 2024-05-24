defmodule GameBackend.Repo.Migrations.AddPurchasableBooleanToItemsTemplates do
  use Ecto.Migration

  def change do
    alter table :item_templates do
      add :purchasable?, :boolean, default: false
      add :characters, {:array, :string}
    end
  end
end
