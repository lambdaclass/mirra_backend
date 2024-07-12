defmodule Configurator.Repo.Migrations.CreateConfigurationEffects do
  use Ecto.Migration

  def change do
    create table(:configuration_effects) do
      add :name, :string
      add :duration_ms, :integer
      add :remove_on_action, :boolean, default: false, null: false
      add :one_time_application, :boolean, default: false, null: false

      add :consumable_item_id, references(:consumable_items, on_delete: :nothing)
      add :mechanics, {:map, :string}

      timestamps(type: :utc_datetime)
    end
  end
end
