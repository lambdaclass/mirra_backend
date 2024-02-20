defmodule GameBackend.Units.Characters.Character do
  @moduledoc """
  Characters are the template on which units are based.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:active, :name, :faction, :quality]}
  schema "characters" do
    field(:game_id, :integer)
    field(:active, :boolean, default: true)
    field(:name, :string)
    field(:title, :string)
    field(:lore, :string)
    field(:faction, :string)
    field(:class, :string)
    field(:quality, :string)

    field(:base_health, :integer)
    field(:base_attack, :integer)
    field(:base_speed, :integer)
    field(:base_defense, :integer)

    timestamps()
  end

  @doc false
  def changeset(character, attrs) do
    character
    |> cast(attrs, [:game_id, :name, :active, :faction, :quality, :title, :lore, :class, :base_health, :base_attack, :base_speed, :base_defense])
    |> validate_required([:game_id, :name, :active, :faction])
  end
end
