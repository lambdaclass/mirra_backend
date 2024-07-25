defmodule GameBackend.Repo.Migrations.AddUserCurrencyCaps do
  use Ecto.Migration

  def change do
    create table(:user_currency_caps) do
      add :currency_id, references(:currencies, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)
      add :cap, :integer, null: :false

      timestamps()
    end

    create index(:user_currency_caps, [:currency_id, :user_id], unique: true)
  end
end
