defmodule GameBackend.Users.Currencies.CurrencyCost do
  @moduledoc """
  Embedded schema for entities' currency cost.
  """
  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.Users.Currencies.Currency

  @primary_key false
  embedded_schema do
    belongs_to(:currency, Currency)
    field(:amount, :integer)
  end

  @doc false
  def changeset(currency_cost, attrs),
    do:
      currency_cost
      |> cast(attrs, [:currency_id, :amount])
      |> validate_required([:currency_id, :amount])
end
