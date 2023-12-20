defmodule DarkWorldsServer.Repo.Migrations.CreateUnits do
  use Ecto.Migration

  def change do
    create table(:units) do
      add :level, :integer, default: 1
      add :selected, :boolean, default: :false
      add :position, :integer

      add :user_id, references(:users, on_delete: :delete_all)
      add :character_id, references(:characters, on_delete: :nilify_all)
      timestamps()
    end

    alter table(:users) do
      remove :selected_character
      remove :most_used_character
    end
  end

end
