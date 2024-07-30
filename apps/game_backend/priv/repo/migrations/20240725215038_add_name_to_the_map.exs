defmodule GameBackend.Repo.Migrations.AddNameToTheMap do
  use Ecto.Migration

  def change do
    alter table(:map_configurations) do
      add :name, :string
    end

    execute("UPDATE map_configurations SET name = 'Araban'",   "")
  end
end
