defmodule GameBackend.Repo.Migrations.RemoveUnusedFieldsFromBuffs do
  use Ecto.Migration

  def change do
    alter table(:buffs) do
      remove :game_id
      remove :name
    end
  end
end
