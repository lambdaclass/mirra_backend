defmodule GameBackend.Repo.Migrations.AddBlockActionsFieldToSkills do
  use Ecto.Migration

  def change do
    alter table(:skills) do
      add :block_actions, :boolean, default: false, null: false
    end
  end
end
