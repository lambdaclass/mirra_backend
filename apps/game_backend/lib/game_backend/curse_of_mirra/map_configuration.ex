defmodule GameBackend.CurseOfMirra.MapConfiguration do
  use GameBackend.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:radius, :initial_positions, :obstacles, :bushes]}
  schema "map_configurations" do
    field :radius, :decimal

    embeds_many :initial_positions, __MODULE__.Position, on_replace: :delete
    embeds_many :obstacles, __MODULE__.Obstacle, on_replace: :delete
    embeds_many :bushes, __MODULE__.Position, on_replace: :delete

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

    @derive {Jason.Encoder, only: [:x, :y]}
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

  defmodule Obstacle do
    use GameBackend.Schema

    @derive {Jason.Encoder, only: [:name, :position, :radius, :shape, :type, :statuses_cycle, :base_status, :vertices]}
    embedded_schema do
      field :name, :string
      field :radius, :decimal
      field :shape, :string
      field :type, :string
      field :base_status, :string
      field :statuses_cycle, :map
      embeds_one :position, Position
      embeds_many :vertices, Position
    end

    def changeset(position, attrs) do
      position
      |> cast(attrs, [:name, :radius, :shape, :type, :base_status, :statuses_cycle])
      |> cast_embed(:position)
      |> cast_embed(:vertices)
      |> validate_required([:name, :position, :radius, :shape, :type])
    end
  end
end
