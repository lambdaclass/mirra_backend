defmodule GameBackend.Gacha.CharacterDropRate do
  @moduledoc """
  The character-box association intermediate table.

  Holds a required `weight` value that defines the drop rate. See Box moduledoc for details.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Characters.Character
  alias GameBackend.Gacha.Box

  schema "character_drop_rates" do
    belongs_to(:box, Box)
    belongs_to(:character, Character)
    field(:weight, :integer)
  end

  @doc false
  def changeset(level_completed, attrs) do
    level_completed
    |> cast(attrs, [:box_id, :character_id, :weight])
    |> validate_required([:character_id, :weight])
  end
end
