defmodule GameBackend.Repo.Migrations.AddPrestigeSystemTables do
  use Ecto.Migration

  def change do
    alter table(:units) do
      add :prestige, :integer
      add :sub_rank, :integer
      modify :selected, :boolean, from: :boolean, null: true
    end
  end
end
