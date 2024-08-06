defmodule GameBackend.Repo.Migrations.AddDefaultForVersionCurrent do
  use Ecto.Migration

  def change do
    alter table(:versions) do
      modify :current, :boolean, default: false
    end
  end
end
