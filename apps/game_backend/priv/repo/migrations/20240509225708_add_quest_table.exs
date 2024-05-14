defmodule GameBackend.Repo.Migrations.AddQuestTable do
  use Ecto.Migration

  def change do
    create table(:quests) do
      add :description, :string
      add :type, :string
      add :config_id, :integer
      add :target, :integer
      add :objective,  :map
      add :reward, :map
      add :conditions, {:array, :map}

      timestamps()
    end

    create(unique_index(:quests, [:config_id]))
  end
end
