defmodule DarkWorldsServer.Repo.Migrations.AddBounceFieldToProjectiles do
  use Ecto.Migration

  def change do
    alter table(:projectiles) do
      add :bounce, :boolean, default: :false
    end
  end
end
