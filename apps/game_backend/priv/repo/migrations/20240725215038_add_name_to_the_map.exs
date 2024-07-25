defmodule GameBackend.Repo.Migrations.AddNameToTheMap do
  use Ecto.Migration

  def change do
    alter table(:map_configurations) do
      add :name, :string
    end
  end
end
