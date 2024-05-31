defmodule Configurator.Repo.Migrations.AddGroupIdAndNameToConfigurations do
  use Ecto.Migration

  def change do
    alter table(:configurations) do
      add :name, :string
      add :configuration_group_id, references(:configuration_groups, on_delete: :nothing)
    end
  end
end
