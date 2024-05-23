defmodule GameBackend.Repo.Migrations.AddItemCostTable do
  use Ecto.Migration

  def change do
    create table(:item_costs) do
      add :name, :string, null: false
      add :currency_costs, {:array, :map}
      add :item_template_id, references(:item_templates, on_delete: :delete_all), null: false
      timestamps()
    end
  end
end
