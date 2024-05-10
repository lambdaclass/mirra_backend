defmodule GameBackend.Repo.Migrations.AddQuestDescriptionTable do
  use Ecto.Migration

  def change do
    create table(:quest_descriptions) do
      add :description, :string, default: ""
      add :type, :string
      add :quest_objectives, {:array, :map}
      timestamps()
    end
  end
end
