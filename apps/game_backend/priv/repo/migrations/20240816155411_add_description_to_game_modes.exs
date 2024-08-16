defmodule GameBackend.Repo.Migrations.AddDescriptionToGameModes do
  use Ecto.Migration

  def change do
    alter table(:game_modes) do
      add :description, :text
    end
  end
end
