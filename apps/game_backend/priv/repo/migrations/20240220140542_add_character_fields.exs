defmodule GameBackend.Repo.Migrations.AddCharacterFields do
  use Ecto.Migration

  def change do
    alter table :characters do
      add :title, :string
      add :lore, :text
      add :class, :string
      add :base_health, :integer
      add :base_attack, :integer
      add :base_speed, :integer
      add :base_defense, :integer
    end
  end
end
