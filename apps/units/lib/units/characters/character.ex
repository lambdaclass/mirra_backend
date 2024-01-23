defmodule Units.Characters.Character do
  @moduledoc """
  Characters are the template on which players are based.
  """

  use Units.Schema
  import Ecto.Changeset

  schema "characters" do
    field(:active, :boolean, default: true)
    field(:name, :string)
    field(:faction, :string)
    field(:rarity, :string)

    timestamps()
  end

  @doc false
  def changeset(character, attrs) do
    character
    |> cast(attrs, [:name, :active, :faction, :rarity])
    |> validate_required([:name, :active, :faction])
  end
end
