defmodule GameBackend.Repo.Migrations.AddDungeonFieldsToLevel do
  use Ecto.Migration

  def change do
    alter(table(:levels)) do
      add(:max_units, :integer)
    end
  end
end
