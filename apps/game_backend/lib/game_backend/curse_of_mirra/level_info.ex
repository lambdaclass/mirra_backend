defmodule GameBackend.CurseOfMirra.LevelInfo do
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
