defmodule GameBackend.Users.Currencies.Currency do
  @moduledoc """
  Currencies.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:name]}
  schema "currencies" do
    field(:game_id, :integer)
    field(:name, :string)
    timestamps()
  end

  @doc false
  def changeset(currency, attrs) do
    currency
    |> cast(attrs, [:game_id, :name])
    |> validate_required([:game_id, :name])
  end
end
