defmodule GameBackend.Repo.Migrations.AddPassiveToCharacters do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add :passive, :map
    end
  end
end
