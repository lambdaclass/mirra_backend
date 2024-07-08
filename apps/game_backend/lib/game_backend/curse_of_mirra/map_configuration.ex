defmodule GameBackend.CurseOfMirra.MapConfiguration do
  use GameBackend.Schema
  import Ecto.Changeset

  schema "map_configurations" do
    field :radius, :decimal
    field :initial_positions, :map
    field :obstacles, :map
    field :bushes, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(map_configuration, attrs) do
    map_configuration
    |> cast(attrs, [:radius, :initial_positions, :obstacles, :bushes])
    |> validate_required([:radius])
  end
end
