defmodule Configurator.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add :name, :string
      add :active, :boolean, default: false, null: false
      add :base_speed, :decimal
      add :base_size, :decimal
      add :base_health, :integer
      add :base_stamina, :integer

      timestamps(type: :utc_datetime)
    end
  end
end