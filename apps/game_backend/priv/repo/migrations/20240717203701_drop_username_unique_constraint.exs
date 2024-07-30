defmodule GameBackend.Repo.Migrations.DropUsernameUniqueConstraint do
  use Ecto.Migration

  def change do
      drop unique_index(:users, [:game_id, :username])
  end
end
