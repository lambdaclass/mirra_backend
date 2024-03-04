defmodule Configurator.Repo.Migrations.CreateConfigurations do
  use Ecto.Migration

  def change do
    create table(:configurations) do
      add :data, :map, null: false
      add :is_default, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:configurations, [:is_default], unique: true, where: "is_default = true")
  end
end
