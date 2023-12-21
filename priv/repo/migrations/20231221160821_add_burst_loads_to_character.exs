defmodule DarkWorldsServer.Repo.Migrations.AddBurstLoadsToCharacter do
  use Ecto.Migration

  def change do
      alter table(:characters) do
        add :burst_loads, :integer
      end
  end
end
