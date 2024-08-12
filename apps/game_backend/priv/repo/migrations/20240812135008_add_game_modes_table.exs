defmodule GameBackend.Repo.Migrations.AddGameModesTable do
  use Ecto.Migration

  def change do
    create table(:game_modes) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:game_modes, [:name]))
  end
end
