defmodule Configurator.Repo.Migrations.AddGameIdAndNameToConfigs do
  use Ecto.Migration

  def change do
    alter table(:configurations) do
      add :game_id, references(:games, on_delete: :nothing)
      add :name, :string
    end
  end
end
