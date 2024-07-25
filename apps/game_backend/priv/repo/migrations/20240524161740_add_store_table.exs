defmodule GameBackend.Repo.Migrations.AddStoreTable do
  use Ecto.Migration

  def change do
    create(table(:stores)) do
      add(:game_id, :integer, null: false)
      add(:name, :string, null: false)
      add(:start_date, :utc_datetime)
      add(:end_date, :utc_datetime)

      timestamps()
    end

    alter(table(:item_templates)) do
      add(:store_id, references(:stores, on_delete: :delete_all))
      remove(:purchasable?, :boolean)
    end
  end
end
