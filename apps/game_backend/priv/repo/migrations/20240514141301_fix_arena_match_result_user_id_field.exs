defmodule GameBackend.Repo.Migrations.FixArenaMatchResultUserIdField do
  use Ecto.Migration

  def change do
    rename table(:arena_match_results), :user_id, to: :google_user_id
  end
end
