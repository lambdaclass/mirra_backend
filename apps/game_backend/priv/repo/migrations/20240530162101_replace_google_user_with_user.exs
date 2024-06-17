defmodule GameBackend.Repo.Migrations.ReplaceGoogleUserWithUser do
  use Ecto.Migration

  def change do
    drop constraint(:arena_match_results, "arena_match_results_user_id_fkey")

    alter table(:arena_match_results) do
      add :user_id, references(:users, on_delete: :nothing)
    end

    execute("""
    UPDATE arena_match_results match
    SET user_id = users.id
    FROM users
    WHERE match.google_user_id = users.google_user_id;
    """)

    alter table(:arena_match_results) do
      remove :google_user_id
      modify :user_id, references(:users, on_delete: :nothing), from: references(:users, on_delete: :nothing), null: false
    end
  end
end
