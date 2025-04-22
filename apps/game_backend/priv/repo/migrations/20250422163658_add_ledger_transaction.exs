defmodule GameBackend.Repo.Migrations.AddLedgerTransaction do
  use Ecto.Migration

  def change do
    create table(:ledger_transactions) do
      add(:type, :string)
      add(:amount, :integer)
      add(:description, :string)
      add(:user_id, references(:users))
      add(:currency_id, references(:currencies))

      timestamps(type: :utc_datetime)
    end
  end
end
