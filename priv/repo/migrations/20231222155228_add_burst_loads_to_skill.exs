defmodule DarkWorldsServer.Repo.Migrations.AddBurstLoadsToSkill do
  use Ecto.Migration

  def change do
    alter table(:skills) do
      add :burst_loads, :integer
    end
  end
end
