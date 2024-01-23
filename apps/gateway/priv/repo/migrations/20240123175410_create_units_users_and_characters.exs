defmodule Gateway.Repo.Migrations.CreateUnitsUsersAndCharacters do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string, null: false
      timestamps()
    end

    create table(:characters) do
      add :active, :boolean, null: false
      add :name, :string, null: false
      add :faction, :string, null: false
      add :rarity, :string
      timestamps()
    end

    create table(:units) do
      add :level, :integer
      add :tier, :integer
      add :selected, :boolean, null: false
      add :slot, :integer
      add :user_id, references(:users, on_delete: :delete_all)
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      timestamps()
    end
  end
end
