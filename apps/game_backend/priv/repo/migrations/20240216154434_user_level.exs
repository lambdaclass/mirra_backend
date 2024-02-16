defmodule :"Elixir.GameBackend.Repo.Migrations.UserLevel" do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :level, :integer, null: false
      add :experience, :bigint, null: false
    end
  end
end
