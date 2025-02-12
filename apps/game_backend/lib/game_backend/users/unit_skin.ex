defmodule GameBackend.Units.UnitSkin do
  @moduledoc """
  The Currencies context.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Unit
  alias GameBackend.Units.Characters.Skin

  @derive {Jason.Encoder,
           only: [
             :unit_id,
             :skin_id,
             :selected
           ]}

  schema "unit_skins" do
    field(:selected, :boolean, default: false)
    belongs_to(:unit, Unit)
    belongs_to(:skin, Skin)

    timestamps()
  end

  @doc false
  def changeset(character, attrs) do
    character
    |> cast(attrs, [:unit_id, :skin_id, :selected])
    |> validate_required([:skin_id])
    |> IO.inspect(label: :aver_changeset_unitskin)
  end
end
