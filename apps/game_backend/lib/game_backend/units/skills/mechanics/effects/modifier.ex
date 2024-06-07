defmodule GameBackend.Units.Skills.Mechanics.Effects.Modifier do
  @moduledoc """
  Modifiers change attributes of characters. Only used for non-Instant effects.

  Operation descriptions
  - `"Add"`: Adds the result to the Modifier's specified Attribute. Use a negative value for subtraction.
  - `"Multiply"`: Multiplies the result to the Modifier's specified Attribute. Use a value between 0 and 1 for division.
  - `"Override"`: Overrides the Modifier's specified Attribute with the result.
  For `"Multiply"`, the `multiply_type` field is used to determine how the value is multiplied. It can be `"Additive"` or `"Multiplicative"`. The default is `"Additive"`. This value is ignored for `"Add"` and `"Override"` operations.

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
        operation: "Multiply",
        magnitude: 0.75
      }

      # Modifier to reduce defense by 100:
      %Modifier{
        attribute: "defense",
        operation: "Add",
        magnitude: -100
      }
  """

  use GameBackend.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:attribute, :string)
    field(:operation, :string)
    field(:magnitude, :float)
    field(:multiply_type, :string)
  end

  def changeset(modifier, attrs) do
    modifier
    |> cast(attrs, [:attribute, :operation, :magnitude, :multiply_type])
    |> validate_inclusion(:operation, ~w[Add Multiply Override])
    |> validate_required([:operation, :magnitude, :attribute])
  end
end
