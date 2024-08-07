defmodule GameBackend.Configuration.Version do
  @moduledoc """
  Version schema.
  """
  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Characters.Character
  alias GameBackend.Items.ConsumableItem
  alias GameBackend.Units.Skills.Skill
  alias GameBackend.CurseOfMirra.MapConfiguration
  alias GameBackend.CurseOfMirra.GameConfiguration

  schema "versions" do
    field(:name, :string)
    field(:current, :boolean, default: false)

    has_many(:characters, Character)
    has_many(:consumable_items, ConsumableItem)
    has_many(:skills, Skill)
    has_many(:map_configurations, MapConfiguration)
    has_one(:game_configuration, GameConfiguration)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(version, attrs) do
    version
    |> cast(attrs, [:name, :current])
    |> validate_required([:name])
  end
end
