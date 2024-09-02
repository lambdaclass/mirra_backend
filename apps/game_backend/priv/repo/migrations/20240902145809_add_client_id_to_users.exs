defmodule GameBackend.Repo.Migrations.AddClientIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :client_id, :string
    end
  end
end
