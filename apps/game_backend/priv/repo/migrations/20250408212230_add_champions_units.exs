defmodule GameBackend.Repo.Migrations.AddChampionsUnits do
  use Ecto.Migration

  def change do
    create table(:champions_units) do
      add :level, :integer
      add :user_id, references(:users, on_delete: :delete_all)
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      timestamps()
    end
  end
end
