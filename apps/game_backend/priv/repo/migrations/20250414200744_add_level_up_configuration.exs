defmodule GameBackend.Repo.Migrations.AddLevelUpConfiguration do
  use Ecto.Migration

  def change do
    create table(:level_up_configurations) do
      add :level_info, {:array, :map}
      add :version_id, references(:versions)

      timestamps(type: :utc_datetime)
    end
  end
end
