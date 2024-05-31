defmodule Configurator.Repo.Migrations.AddGameConfigGroup do
  use Ecto.Migration

  def change do
    create table(:configuration_groups) do
      add :name, :string, null: false
      add :game_id, references(:games, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end
  end
end
