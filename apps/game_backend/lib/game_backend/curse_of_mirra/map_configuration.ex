defmodule GameBackend.CurseOfMirra.MapConfiguration do
  use GameBackend.Schema
  import Ecto.Changeset

  schema "map_configurations" do
    field :radius, :decimal

    embeds_many :initial_positions, __MODULE__.Position
    embeds_many :obstacles, __MODULE__.Position
    embeds_many :bushes, __MODULE__.Position

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(map_configuration, attrs) do
    map_configuration
    |> cast(attrs, [:radius])
    |> validate_required([:radius])
    |> cast_embed(:initial_positions)
    |> cast_embed(:obstacles)
    |> cast_embed(:bushes)
  end

  defmodule Position do
    use GameBackend.Schema

    embedded_schema do
      field :x, :decimal
      field :y, :decimal
    end

    def changeset(position, attrs) do
      position
      |> cast(attrs, [:x, :y])
      |> validate_required([:x, :y])
    end
  end
end
