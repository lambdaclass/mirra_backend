defmodule GameBackend.Repo.Migrations.AddRankToUnits do
  use Ecto.Migration

  def change do
    alter table(:units) do
      add :rank, :integer
    end
  end
end
