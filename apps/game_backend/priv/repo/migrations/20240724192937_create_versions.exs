defmodule Configurator.Repo.Migrations.CreateVersions do
  use Ecto.Migration

  def change do
    create table(:versions) do
      add :name, :string
      add :current, :boolean

      timestamps(type: :utc_datetime)
    end
  end
end
