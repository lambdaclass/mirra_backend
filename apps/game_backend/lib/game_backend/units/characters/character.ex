defmodule GameBackend.Units.Characters.Character do
  @moduledoc """
  Characters are the template on which units are based.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:active, :name, :faction, :rarity]}
  schema "characters" do
    field(:game_id, :integer)
    field(:active, :boolean, default: true)
    field(:name, :string)
    field(:faction, :string)
    field(:rarity, :integer)

    timestamps()
  end

  @doc false
  def changeset(character, attrs) do
    character
    |> cast(attrs, [:game_id, :name, :active, :faction, :rarity])
    |> validate_required([:game_id, :name, :active, :faction])
  end
end
