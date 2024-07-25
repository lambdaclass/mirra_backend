defmodule GameBackend.Repo.Migrations.AddBushParameterToGameConfiguration do
  use Ecto.Migration

  def change do
    alter table(:game_configurations) do
      add :field_of_view_inside_bush, :integer
    end
  end
end
