defmodule GameBackend.CurseOfMirra.MapConfiguration do
  @moduledoc """
  MapConfiguration schema
  """
  use GameBackend.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:name, :radius, :initial_positions, :obstacles, :bushes, :pools]}
  schema "map_configurations" do
    field(:name, :string)
    field(:radius, :decimal)

    embeds_many(:initial_positions, __MODULE__.Position, on_replace: :delete)
    embeds_many(:obstacles, __MODULE__.Obstacle, on_replace: :delete)
    embeds_many(:bushes, __MODULE__.Position, on_replace: :delete)
    embeds_many(:pools, __MODULE__.Pool, on_replace: :delete)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(map_configuration, attrs) do
    map_configuration
    |> cast(attrs, [:radius, :name])
    |> validate_required([:radius])
    |> cast_embed(:initial_positions)
    |> cast_embed(:obstacles)
    |> cast_embed(:bushes)
    |> cast_embed(:pools)
    |> unique_constraint(:name)
  end

  defmodule Position do
    @moduledoc """
    Position embedded schema to be used by MapConfiguration
    """
    use GameBackend.Schema

    @derive {Jason.Encoder, only: [:x, :y]}
    embedded_schema do
      field(:x, :decimal)
      field(:y, :decimal)
    end

    def changeset(position, attrs) do
      position
      |> cast(attrs, [:x, :y])
      |> validate_required([:x, :y])
    end
  end

  defmodule Obstacle do
    @moduledoc """
    Obstacle embedded schema to be used by MapConfiguration
    """
    alias GameBackend.CurseOfMirra.MapConfiguration
    use GameBackend.Schema

    @derive {Jason.Encoder, only: [:name, :position, :radius, :shape, :type, :statuses_cycle, :base_status, :vertices]}
    embedded_schema do
      field(:name, :string)
      field(:radius, :decimal)
      field(:shape, :string)
      field(:type, Ecto.Enum, values: [:static, :dynamic, :lake])
      field(:base_status, :string)
      field(:statuses_cycle, :map)
      embeds_one(:position, Position)
      embeds_many(:vertices, Position)
    end

    def changeset(position, attrs) do
      position
      |> cast(attrs, [:name, :radius, :shape, :type, :base_status, :statuses_cycle])
      |> cast_embed(:position)
      |> cast_embed(:vertices)
      |> validate_required([:name, :position, :radius, :shape, :type])
      |> MapConfiguration.validate_shape()
    end
  end

  defmodule Pool do
    @moduledoc """
    Pool embedded schema to be used by MapConfiguration
    """
    alias GameBackend.CurseOfMirra.MapConfiguration
    use GameBackend.Schema

    @derive {Jason.Encoder, only: [:name, :position, :radius, :shape, :vertices, :effects_to_apply]}
    embedded_schema do
      field(:name, :string)
      field(:radius, :decimal)
      field(:shape, Ecto.Enum, values: [:circle, :polygon])
      field(:effects_to_apply, {:array, :string})
      embeds_one(:position, Position)
      embeds_many(:vertices, Position)
    end

    def changeset(position, attrs) do
      position
      |> cast(attrs, [:name, :radius, :shape, :effects_to_apply])
      |> cast_embed(:position)
      |> cast_embed(:vertices, drop_param: :vertices_drop, sort_param: :vertices_sort)
      |> validate_required([:name, :position, :radius, :shape, :effects_to_apply])
      |> MapConfiguration.validate_shape()
    end
  end

  def validate_shape(changeset) do
    case get_field(changeset, :shape) do
      :polygon ->
        if Enum.count(get_field(changeset, :vertices)) < 3 do
          add_error(changeset, :shape, "A polygon requires at least 3 vertices")
        else
          changeset
        end

      :circle ->
        changeset
        |> validate_number(:radius, greater_than_or_equal_to: 0)

      _ ->
        changeset
    end
  end
end
