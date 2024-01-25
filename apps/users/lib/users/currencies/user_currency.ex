defmodule Users.Currencies.UserCurrency do
  @moduledoc """
  The User-Currency association intermediate table.
  """

  use Users.Schema
  import Ecto.Changeset

  alias Users.Currencies.Currency
  alias Users.User

  @derive {Jason.Encoder, only: [:currency, :amount]}
  schema "user_currencies" do
    belongs_to(:currency, Currency)
    belongs_to(:user, User)
    field(:amount, :integer)

    timestamps()
  end

  @doc false
  def changeset(user_currency, attrs) do
    user_currency
    |> cast(attrs, [:currency_id, :user_id, :amount])
    |> validate_required([:currency_id, :user_id, :amount])
  end

  @doc false
  def update_changeset(user_currency, attrs) do
    user_currency
    |> cast(attrs, [:amount])
    |> validate_required([:amount])
  end
end
