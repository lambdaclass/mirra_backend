defmodule GameBackend.Repo.Migrations.AddActiveToMapConfig do
  use Ecto.Migration

  def change do
    alter table(:map_configurations) do
      add :active, :boolean, default: :false
    end
  end
end
