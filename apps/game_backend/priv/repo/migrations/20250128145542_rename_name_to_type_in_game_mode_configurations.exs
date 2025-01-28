defmodule GameBackend.Repo.Migrations.RenameNameToTypeInGameModeConfigurations do
  use Ecto.Migration

  def change do
    rename table(:game_mode_configurations), :name, to: :type

    alter table(:game_mode_configurations) do
      add :name, :string
    end
  end
end
