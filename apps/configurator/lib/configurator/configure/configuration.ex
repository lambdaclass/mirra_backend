defmodule Configurator.Configure.Configuration do
  @moduledoc """
  Configuration in DB
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Configurator.Games.Game

  schema "configurations" do
    field :name, :string
    field :data, :string
    field :is_default, :boolean, default: false

    belongs_to :game, Game

    timestamps(type: :utc_datetime)
  end

  @required [
    :data,
    :is_default,
    :data,
    :game_id
  ]

  @doc false
  def changeset(configuration, attrs) do
    configuration
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> validate_change(:data, &valid_json?/2)
  end

  defp valid_json?(field, data) do
    case Jason.decode(data) do
      {:ok, _} -> []
      {:error, _} -> [{field, "is not valid JSON"}]
    end
  end
end
