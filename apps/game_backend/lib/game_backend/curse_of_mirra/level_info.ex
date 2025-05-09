defmodule GameBackend.CurseOfMirra.LevelInfo do
  @moduledoc """
  LevelInfo schema

  Embedded schema used to store all the level up config for a particular level.
  This includes all the costs in possibly more than one currency and the
  increase percentage from the base stats
  """
  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.Users.Currencies.CurrencyCost

  embedded_schema do
    field(:level, :integer)
    field(:stat_increase_percentage, :integer)

    embeds_many(:currency_costs, CurrencyCost, on_replace: :delete)
  end

  def changeset(level_info, attrs) do
    level_info
    |> cast(attrs, [:level, :stat_increase_percentage])
    |> validate_required([:level, :stat_increase_percentage])
    |> cast_embed(:currency_costs)
  end
end
