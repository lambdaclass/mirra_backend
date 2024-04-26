defmodule GameBackend.Repo.Migrations.AddKalineTreeLevelToUser do
  use Ecto.Migration

  def change do
    create table(:kaline_tree_levels) do
      add :level, :integer
      add :fertilizer_level_up_cost, :integer
      add :gold_level_up_cost, :integer
      add :unlock_features, {:array, :string}
      timestamps()
    end

    alter table(:users) do
      add :kaline_tree_level_id, references(:kaline_tree_levels, on_delete: :nothing)
    end

    create unique_index(:kaline_tree_levels, [:level])
  end
end
