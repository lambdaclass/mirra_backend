defmodule GameBackend.Repo.Migrations.Gacha do
  use Ecto.Migration

  def change do
    create table(:boxes) do
      add :name, :string, null: false
      add :description, :string
      add :cost, :map
      timestamps()
    end

    create table(:character_drop_rates) do
      add :box_id, references(:boxes, on_delete: :delete_all)
      add :character_id, references(:characters, on_delete: :delete_all)
      add :weight, :integer, null: false
    end
  end
end
