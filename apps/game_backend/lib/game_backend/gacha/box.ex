defmodule GameBackend.Gacha.Box do
  @moduledoc """
  Boxes are opened by users in order to obtain units.
  They have combinations of characters and drop rates, as well as an unique name.

  The way drop rates work is that each character on the pool has a "weight" that impacts how likely
  they are to be returned. This way we avoid messing with percentages wich are messier.
  For example, if we wanted 4 characters in our pool, with the same odds of dropping, we can set 1 as the weight for each.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Users.Currencies.CurrencyCost
  alias GameBackend.Units.Characters.Character
  alias GameBackend.Gacha.CharacterDropRate

  schema "boxes" do
    field(:name, :string)
    field(:description, :string)

    has_many(:character_drop_rates, CharacterDropRate)
    many_to_many(:characters, Character, join_through: CharacterDropRate)
    embeds_many(:cost, CurrencyCost)

    timestamps()
  end

  @doc false
  def changeset(character, attrs),
    do:
      character
      |> cast(attrs, [:name, :description])
      |> cast_assoc(:character_drop_rates)
      |> cast_embed(:cost)
      |> validate_required([:name])
end
