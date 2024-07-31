defmodule GameBackend.Repo.Migrations.AddPoolsToGameConfiguration do
  use Ecto.Migration

  def change do
    alter table(:map_configurations) do
      add :pools, :map
    end
  end
end
