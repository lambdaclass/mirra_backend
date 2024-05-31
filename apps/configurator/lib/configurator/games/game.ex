defmodule Configurator.Games.Game do
  @moduledoc """
  Schema in charge of to group configuration groups by games.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :name, :string
    timestamps(type: :utc_datetime)
  end

  @required [
    :name
  ]

  def changeset(game, attrs) do
    game
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
