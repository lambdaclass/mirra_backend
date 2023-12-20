defmodule DarkWorldsServer.Repo.Migrations.CreateUnits do
  use Ecto.Migration

  def change do
    create table(:units) do
      add :level, :integer, default: 1
      add :selected, :boolean, default: :false
      add :position, :integer

      add :character_id, references(:characters, on_delete: :nilify_all)
      timestamps()
    end

    create table(:user_units) do
      add :user_id, references(:users, on_delete: :delete_all), null: :false
      add :unit_id, references(:units, on_delete: :delete_all), null: :false
      timestamps()
    end

    alter table(:users) do
      remove :selected_character
    end
  end

end
