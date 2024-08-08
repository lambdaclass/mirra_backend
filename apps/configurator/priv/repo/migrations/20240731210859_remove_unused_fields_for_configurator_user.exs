defmodule Configurator.Repo.Migrations.RemoveUnusedFieldsForConfiguratorUser do
  use Ecto.Migration

  def change do
    alter table(:configurator_users) do
      remove :hashed_password, :string, null: false
      remove :confirmed_at, :naive_datetime
    end
  end
end
