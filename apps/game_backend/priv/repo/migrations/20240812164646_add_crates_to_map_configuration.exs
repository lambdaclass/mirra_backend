defmodule GameBackend.Repo.Migrations.AddCratesToMapConfiguration do
  use Ecto.Migration

  def change do
    alter table(:map_configurations) do
      add :crates, :map
    end
  end
end
