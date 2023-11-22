defmodule DarkWorldsServer.Repo.Migrations.AddNewFieldsToUsersSchema do
  use Ecto.Migration

  def change do

    drop table(:users_tokens)
    drop table(:users)

    create table(:users) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      add :username, :string
      add :selected_character, :string
      add :device_client_id, :string
      add :total_kills, :integer, default: 0
      add :total_wins, :integer, default: 0
      add :most_used_character, :string
      add :experience, :float, default: 0

      timestamps()
    end

    create unique_index(:users, :username)
    create unique_index(:users, :device_client_id)
    create unique_index(:users, [:email])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end
end
