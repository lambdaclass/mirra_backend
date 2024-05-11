defmodule GameBackend.Repo.Migrations.CreateAttributes do
  use Ecto.Migration

  def change do
    execute "CREATE SCHEMA IF NOT EXISTS common", "DROP SCHEMA IF EXISTS common CASCADE"
    execute "CREATE SCHEMA IF NOT EXISTS curse", "DROP SCHEMA IF EXISTS curse CASCADE"
    execute "CREATE SCHEMA IF NOT EXISTS champions", "DROP SCHEMA IF EXISTS champions CASCADE"

    create table("demo_users", prefix: "common") do
      add :name, :string
      add :email, :string
      timestamps()
    end

    create unique_index("demo_users", [:email], prefix: "common")

    create table("demo_currencies", prefix: "common") do
      add :name, :string
      timestamps()
    end

    for prefix <- ["curse", "champions"] do
      create table("currency_transactions", prefix: prefix) do
        add :user_id, references("demo_users", prefix: "common")
        add :demo_currency_id, references("demo_currencies", prefix: "common")
        add :amount, :integer
        timestamps()
      end
    end

    create table("user_attributes", prefix: "champions") do
      add :user_id, references("demo_users", prefix: "common")
      add :rank, :integer
      add :last_reward_at, :utc_datetime
      add :last_transaction_id, references("currency_transactions")
      timestamps()
    end
  end
end
