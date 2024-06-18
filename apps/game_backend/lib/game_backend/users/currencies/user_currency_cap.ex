defmodule GameBackend.Users.Currencies.UserCurrencyCap do
  @moduledoc """
  Represents a limit on the amount of a currency a user can have at any time.

  If a User has no UserCurrencyCap for a given Currency, they can have an unlimited amount of that Currency.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Users.Currencies.Currency
  alias GameBackend.Users.User

  schema "user_currency_caps" do
    belongs_to(:currency, Currency)
    belongs_to(:user, User)
    field(:cap, :integer)

    timestamps()
  end

  @doc false
  def changeset(user_currency_cap, attrs) do
    user_currency_cap
    |> cast(attrs, [:currency_id, :user_id, :cap])
    |> validate_number(:cap, greater_than_or_equal_to: 0)
    |> validate_required([:currency_id, :user_id, :cap])
  end

  @doc false
  def update_changeset(user_currency_cap, attrs) do
    user_currency_cap
    |> cast(attrs, [:cap])
    |> validate_required([:cap])
  end
end
