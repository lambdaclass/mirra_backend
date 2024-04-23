defmodule GameBackend.Repo.Migrations.AddKalineTreeLevelToUser do
  use Ecto.Migration

  def change do
    create table(:kaline_tree_levels) do
      add :level, :integer
      add :fertilizer_cost, :integer
      add :gold_cost, :integer
      add :unlock_features, {:array, :string}
      add :user_id, references(:users, on_delete: :nothing)
      timestamps()
    end

    alter table(:users) do
      add :kaline_tree_level_id, references(:kaline_tree_levels, on_delete: :nothing)
    end
  end
end
