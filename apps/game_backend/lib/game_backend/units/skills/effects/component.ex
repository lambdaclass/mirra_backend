defmodule GameBackend.Units.Skills.Effects.Component do
  @moduledoc """
  Components are objects that can change the behavior of effects.

  Some examples:

  - Chance to Apply (float)
    - Determines a percentage chance that needs to be rolled in order for the effect to work.
  - Apply Tags
    - For the duration of the effect, tags will be applied to the unit.
  - Target Tag Requirements
    - Limit the effect to only work when the actor has certain tags.

  Note that the Tag components will contain a lot more options down the road,
  such as separating tag requirements for Ongoing/Activation/Removal parts of an effect.
  Also being able to specify a required tag or a tag required to *not* be present.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:todo, :string)
  end

  def changeset(component, attrs) do
    component
    |> cast(attrs, [:todo])
  end
end
