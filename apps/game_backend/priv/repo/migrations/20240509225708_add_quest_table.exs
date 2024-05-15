defmodule GameBackend.Repo.Migrations.AddQuestTable do
  use Ecto.Migration

  def change do
    create table(:quests) do
      add :description, :string, null: false
      add :type, :string, null: false
      add :config_id, :integer, null: false
      add :objective,  :map
      add :reward, :map
      add :conditions, {:array, :map}

      timestamps()
    end

    create(unique_index(:quests, [:config_id]))
  end
end
