defmodule Configurator.Repo.Migrations.DeleteConfiguratorCharacters do
  use Ecto.Migration

  def change do
    drop table(:characters_config)
  end
end
