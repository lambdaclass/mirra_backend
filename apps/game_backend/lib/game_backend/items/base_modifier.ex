defmodule GameBackend.Items.BaseModifier do
  @moduledoc """
  Item BaseModifiers change attributes of a character while the Item is equipped.

  Operation descriptions
  - `"Add"`: Adds the result to the Base Modifier's specified Attribute. Use a negative value for subtraction.
  - `"Multiply"`: Multiplies the result to the Base Modifier's specified Attribute. Use a value between 0 and 1 for division.

  The `CurrentValue` of an `Attribute` is the aggregate result of all of its `Modifiers` added to its `BaseValue`.
  The formula for how `Base Modifiers` are aggregated is defined as follows:

  ```
  (InlineBaseValue + Additive) * Multiplicative
  ```

  ## Examples
      # Base Modifier to increment attack by 5%:
      %BaseModifier{
        attribute: "attack",
        operation: "Multiply",
        base_value: 1.05
      }

      # Base Modifier to increment defense by 100:
      %BaseModifier{
        attribute: "defense",
        operation: "Add",
        base_value: 100
      }
  """

  use GameBackend.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:attribute, :string)
    field(:operation, :string)
    field(:base_value, :float)
  end

  @doc """
  Builds a changeset based on the `modifier` and `attrs`.
  """
  def changeset(modifier, attrs) do
    modifier
    |> cast(attrs, [:attribute, :operation, :base_value])
    |> validate_inclusion(:operation, ~w[Add Multiply])
    |> validate_required([:operation, :base_value, :attribute])
  end
end
