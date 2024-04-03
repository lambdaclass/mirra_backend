defmodule GameBackend.Units.Skills.Effects.Modifier do
  @moduledoc """
  Modifiers change attributes of characters. Only used for non-Instant effects.

  Operation descriptions
  - `"Add"`: Adds the result to the Modifier's specified Attribute. Use a negative value for subtraction.
  - `"Multiply"`: Multiplies the result to the Modifier's specified Attribute. Use a value between 0 and 1 for division.
  - `"Override"`: Overrides the Modifier's specified Attribute with the result.

  The `CurrentValue` of an `Attribute` is the aggregate result of all of its `Modifiers` added to its `BaseValue`.
  The formula for how `Modifiers` are aggregated is defined as follows:

  ```
  (InlineBaseValue + Additive) * Multiplicative
  ```

  Any `"Override"` `Modifiers` will override the final value with the last applied `Modifier` taking precedence.

  Examples:
      # Modifier to reduce damage by 25%:
      %Modifier{
        attribute: "damage",
        modifier_operation: "Multiply",
        float_magnitude: 0.75
      }

      # Modifier to reduce defense by 100:
      %Modifier{
        attribute: "defense",
        modifier_operation: "Add",
        float_magnitude: -100
      }
  """

  use GameBackend.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:attribute, :string)
    field(:modifier_operation, :string)
    field(:float_magnitude, :float)
  end

  def changeset(modifier, attrs) do
    modifier
    |> cast(attrs, [:attribute, :modifier_operation, :float_magnitude])
    |> validate_inclusion(:modifier_operation, ~w[Add Multiply Override])
    |> validate_required([:modifier_operation, :float_magnitude, :attribute])
  end
end
