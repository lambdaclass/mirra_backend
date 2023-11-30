defmodule DarkWorldsServer.Repo.Migrations.AddUsernameToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :string
    end

    create unique_index(:users, :username)
  end
end
