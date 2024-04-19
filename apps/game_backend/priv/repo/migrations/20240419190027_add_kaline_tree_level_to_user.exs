defmodule GameBackend.Repo.Migrations.AddKalineTreeLevelToUser do
  use Ecto.Migration

  def change do
    alter table :users do
      add :kaline_tree_level, :integer
    end
  end
end
