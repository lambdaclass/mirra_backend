defmodule GameBackend.Configuration.GameMode do
  use GameBackend.Schema
  import Ecto.Changeset

  schema "game_modes" do
    field(:name, :string)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game_mode, attrs) do
    game_mode
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
