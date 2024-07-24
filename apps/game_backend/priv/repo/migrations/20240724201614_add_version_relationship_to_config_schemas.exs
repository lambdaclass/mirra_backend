defmodule GameBackend.Repo.Migrations.AddVersionRelationshipToConfigSchemas do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add :version_id, references(:versions)
    end

    alter table(:consumable_items) do
      add :version_id, references(:versions)
    end

    alter table(:skills) do
      add :version_id, references(:versions)
    end

    alter table(:game_configurations) do
      add :version_id, references(:versions)
    end
  end

end
