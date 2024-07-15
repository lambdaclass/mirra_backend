defmodule GameBackend.CurseOfMirra.MapConfiguration do
  use GameBackend.Schema
  import Ecto.Changeset

  schema "map_configurations" do
    field :radius, :decimal

    @derive Jason.Encoder
    embeds_many :initial_positions, __MODULE__.Position, on_replace: :delete
    @derive Jason.Encoder
    embeds_many :obstacles, __MODULE__.Obstacle, on_replace: :delete
    @derive Jason.Encoder
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
      embeds_one :position, Position
      field :radius, :decimal
      field :shape, :string
      field :type, :string
      field :statuses_cycle, :map
      field :base_status, :string
      embeds_many :vertices, Position
    end

    def changeset(position, attrs) do
      position
      |> cast(attrs, [:name, :radius, :shape, :type, :statuses_cycle, :base_status])
      |> cast_embed(:position)
      |> cast_embed(:vertices)
      |> validate_required([:name, :position, :radius, :shape, :type, :statuses_cycle])
  end
  end
end
