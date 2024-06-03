defmodule GameBackend.Users.Currencies.Currency do
  @moduledoc """
  Currencies.
  """
  alias GameBackend.Stores.Buyable

  use GameBackend.Schema
  import Ecto.Changeset

  schema "currencies" do
    field(:game_id, :integer)
    field(:name, :string)
    belongs_to(:buyable, Buyable)
    timestamps()
  end

  @doc false
  def changeset(currency, attrs) do
    currency
    |> cast(attrs, [:game_id, :name, :buyable_id])
    |> validate_required([:game_id, :name])
  end
end
