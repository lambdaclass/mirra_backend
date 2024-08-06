defmodule GameBackend.Repo.Migrations.AddTimeVisibleInBushAfterSkill do
  use Ecto.Migration

  def change do
    alter table(:game_configurations) do
      add :time_visible_in_bush_after_skill, :integer
    end

    execute("UPDATE game_configurations SET time_visible_in_bush_after_skill = 2000 WHERE time_visible_in_bush_after_skill IS NULL ",   "")
  end
end
