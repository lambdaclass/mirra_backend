defmodule GameBackend.Repo.Migrations.AddGameModesTable do
  use Ecto.Migration

  def change do
    create table(:game_modes) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
