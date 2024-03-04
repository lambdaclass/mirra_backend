defmodule Configurator.Repo.Migrations.CreateConfigurations do
  use Ecto.Migration

  def change do
    create table(:configurations) do
      add :data, :map
      add :is_default, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
