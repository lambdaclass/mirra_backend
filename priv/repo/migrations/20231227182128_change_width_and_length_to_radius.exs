defmodule DarkWorldsServer.Repo.Migrations.ChangeWidthAndLengthToRadius do
  use Ecto.Migration

  def change do
    alter table(:games) do
      remove :width
      remove :height
      add :outer_radius, :integer
      add :inner_radius, :integer
    end
  end
end
