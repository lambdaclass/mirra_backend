defmodule GameBackend.Repo.Migrations.AddIsBossStageFieldToLevel do
  use Ecto.Migration

  def change do
    alter table(:levels) do
      add :is_boss_stage?, :boolean, default: false
    end
  end
end
