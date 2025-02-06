defmodule GameBackend.Units.Characters.Skin do
  @moduledoc """
  Characters are the template on which units are based.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Characters.Character

  @derive {Jason.Encoder,
           only: [
             :is_default,
             :character_id
           ]}

  schema "skins" do
    field(:is_default, :boolean, default: false)
    belongs_to(:character, Character)

    timestamps()
  end

  @doc false
  def changeset(character, attrs) do
    character
    |> cast(attrs, [
      :is_default,
      :character_id
    ])
    |> validate_required([:is_default, :character_id])
  end
end
