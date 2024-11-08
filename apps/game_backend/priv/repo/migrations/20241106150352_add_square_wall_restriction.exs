defmodule GameBackend.Repo.Migrations.AddSquareWallRestriction do
  use Ecto.Migration

  def change do
    alter table(:map_configurations) do
      add :square_wall, :map
    end
  end
end
