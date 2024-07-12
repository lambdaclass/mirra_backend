defmodule GameBackend.CurseOfMirra.MapConfiguration do
  use GameBackend.Schema
  import Ecto.Changeset

  schema "map_configurations" do
    field :radius, :decimal

    @derive Jason.Encoder
    embeds_many :initial_positions, __MODULE__.Position
    embeds_many :obstacles, __MODULE__.Position
    embeds_many :bushes, __MODULE__.Position

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(map_configuration, attrs) do
    IO.inspect(attrs, label: "map attrs")
    map_configuration
    |> cast(attrs, [:radius])
    |> validate_required([:radius])
    |> cast_embed(:initial_positions)
    |> cast_embed(:obstacles)
    |> cast_embed(:bushes)
  end

  defmodule Position do
    use GameBackend.Schema

    @derive {Jason.Encoder, only: [:x, :y]}
    embedded_schema do
      field :x, :decimal
      field :y, :decimal
    end

    def changeset(position, attrs) do
      IO.inspect(position, label: "position")
      IO.inspect(attrs, label: "attrs")
      position
      |> cast(attrs, [:x, :y])
      |> validate_required([:x, :y])
    end
  end
end
