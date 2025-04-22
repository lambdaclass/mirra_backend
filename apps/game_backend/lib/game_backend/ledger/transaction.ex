defmodule GameBackend.Ledger.Transaction do
  @moduledoc """
  The ledger will be used to keep track of a transaction log of each game
  """
  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Users.User
  alias GameBackend.Users.Currencies.Currency

  schema "ledger_transactions" do
      field(:type, Ecto.Enum, values: [:credit, :debit])
      field(:amount, :integer)
      field(:description, :string)

      belongs_to(:user, User)
      belongs_to(:currency, Currency)

      timestamps(type: :utc_datetime)
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :type,
      :amount,
      :description,
      :user_id,
      :currency_id,
    ])
    |> validate_required([:type, :amount, :description, :user_id, :currency_id])
  end
end
