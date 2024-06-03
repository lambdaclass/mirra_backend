defmodule GameBackend.Repo.Migrations.AddBuyablesTable do
  use Ecto.Migration

  def change do
    create table(:buyables) do
      add(:store_id, references(:stores, on_delete: :delete_all))
      add(:name, :string, null: false)
      add(:stock, :integer)
      add(:amount, :integer)
      add(:purchase_costs, {:array, :map})
    end

    alter table(:currencies) do
      add(:buyable_id, references(:buyables, on_delete: :delete_all))
    end

    alter table(:item_templates) do
      add(:buyable_id, references(:buyables, on_delete: :delete_all))
      remove(:store_id, references(:stores, on_delete: :delete_all))
      remove(:purchase_costs, {:array, :map})
    end
  end
end
