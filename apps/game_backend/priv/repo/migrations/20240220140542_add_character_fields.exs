defmodule GameBackend.Repo.Migrations.AddCharacterFields do
  use Ecto.Migration

  def change do
    alter table :characters do
      add :title, :string
      add :lore, :text
      add :class, :string
    end
  end
end
