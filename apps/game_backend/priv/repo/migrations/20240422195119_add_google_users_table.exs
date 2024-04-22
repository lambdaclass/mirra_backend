defmodule GameBackend.Repo.Migrations.AddGoogleUsersTable do
  use Ecto.Migration

  def change do
    create table(:google_users) do
      add :email, :string, null: false
      timestamps()
    end

    create unique_index(:google_users, [:email])
  end
end
