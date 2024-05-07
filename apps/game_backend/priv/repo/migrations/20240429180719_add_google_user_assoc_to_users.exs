defmodule GameBackend.Repo.Migrations.AddGoogleUserAssocToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :google_user_id, references(:google_users, on_delete: :delete_all)
      add :profile_picture, :string
    end
  end
end
