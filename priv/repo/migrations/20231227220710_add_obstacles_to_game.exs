defmodule DarkWorldsServer.Repo.Migrations.AddObstaclesToGame do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :obstacles, {:array, :map}
    end
  end
end
