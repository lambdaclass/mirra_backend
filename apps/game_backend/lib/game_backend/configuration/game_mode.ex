defmodule GameBackend.Configuration.GameMode do
  @moduledoc """
  GameMode schema
  """
  use GameBackend.Schema
  import Ecto.Changeset

  schema "game_modes" do
    field(:name, :string)
    field(:description, :string)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game_mode, attrs) do
    game_mode
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
    |> unique_constraint(:name)
  end
end
