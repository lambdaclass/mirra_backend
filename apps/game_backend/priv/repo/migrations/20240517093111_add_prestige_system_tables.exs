defmodule GameBackend.Repo.Migrations.AddPrestigeSystemTables do
  use Ecto.Migration

  def change do
    create table(:character_prestiges) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :character, :string, null: false
      add :rank, :string, null: false
      add :sub_rank, :integer, null: false
      add :amount, :integer, null: false
      timestamps()
    end

    create unique_index(:character_prestiges, [:user_id, :character])
  end
end
