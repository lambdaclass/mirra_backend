defmodule GameBackend.Gacha.Box do
  @moduledoc """
  Boxes are opened by users in order to obtain units.
  They have determined odds of dropping different rank units. The specific character that's dropped is calculated afterwards,
  with equal chances for all. The factions field can be set to only allow for units from specific factions to drop.

  The way rank weights work is that each possible rank on the pool has a "weight" that impacts how likely they are to be returned.
  For example, if we wanted 4 different ranks in our pool, with the same odds of dropping, we can set 1 as the weight for each.
  This way we avoid using percentages wich are messier.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Users.Currencies.CurrencyCost
  alias GameBackend.Gacha.RankWeights

  schema "boxes" do
    field(:name, :string)
    field(:description, :string)
    field(:factions, {:array, :string})

    embeds_many(:cost, CurrencyCost)
    embeds_many(:rank_weights, RankWeights)

    timestamps()
  end

  @doc false
  def changeset(character, attrs),
    do:
      character
      |> cast(attrs, [:name, :description, :factions])
      |> cast_embed(:cost)
      |> cast_embed(:rank_weights)
      |> validate_required([:name])
end
