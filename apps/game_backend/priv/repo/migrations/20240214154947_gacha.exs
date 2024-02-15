defmodule GameBackend.Repo.Migrations.Gacha do
  use Ecto.Migration

  def change do
    create table(:boxes) do
      add :name, :string, null: false
      add :description, :string
      add :factions, {:array, :string}
      add :cost, :map
      add :rank_weights, :map
      timestamps()
    end

    alter table(:characters) do
      add :ranks_dropped_in, {:array, :integer}
    end
  end
end
