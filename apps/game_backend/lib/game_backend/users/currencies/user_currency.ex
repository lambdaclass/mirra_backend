defmodule GameBackend.Users.Currencies.UserCurrency do
  @moduledoc """
  The User-Currency association intermediate table.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Users.Currencies.Currency
  alias GameBackend.Users.User
  alias GameBackend.Repo

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
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> validate_required([:currency_id, :user_id, :amount])
  end

  @doc false
  def update_changeset(user_currency, attrs) do
    user_currency
    |> cast(attrs, [:amount])
    |> validate_required([:amount])
  end

  def preload_currency(user_currency), do: Repo.preload(user_currency, [:currency])
end
