defmodule Configurator.Repo.Migrations.CreateGamesTable do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :name, :string
      timestamps(type: :utc_datetime)
    end
  end
end
