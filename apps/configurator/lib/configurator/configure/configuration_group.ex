defmodule Configurator.Configure.ConfigurationGroup do
  @moduledoc """
  ConfigurationGroup in DB
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Configurator.Games.Game

  schema "configuration_groups" do
    field :name, :string

    belongs_to :game, Game

    timestamps(type: :utc_datetime)
  end

  @required [:name, :game_id]

  def changeset(configuration_group, attrs) do
    configuration_group
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
