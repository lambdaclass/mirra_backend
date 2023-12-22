defmodule DarkWorldsServer.Repo.Migrations.AddTickrateFieldToConfig do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :tick_interval_ms, :integer
    end
  end
end
