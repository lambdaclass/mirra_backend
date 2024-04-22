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
  end
end
