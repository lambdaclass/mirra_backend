defmodule DarkWorldsServer.Config.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset
  alias DarkWorldsServer.Config.Games.ZoneModification

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "games" do
    field(:width, :integer)
    field(:height, :integer)
    field(:loot_interval_ms, :integer)
    field(:zone_starting_radius, :integer)
    field(:auto_aim_max_distance, :float)
    field(:initial_positions, {:array, :map})

    has_many(:zone_modifications, ZoneModification)

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [
      :width,
      :height,
      :loot_interval_ms,
      :zone_starting_radius,
      :auto_aim_max_distance,
      :initial_positions
    ])
    |> validate_required([:width, :height, :auto_aim_max_distance])
    |> cast_assoc(:zone_modifications)
  end
end
