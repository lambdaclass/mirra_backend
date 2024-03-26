defmodule GameBackend.Units.Skills.Effects.Component do
  @moduledoc """
  Components are objects that can change the behavior of effects.

  Some examples:

  - Chance to Apply (float)
    - Determines a percentage chance that needs to be rolled in order for the effect to work.
      Example:
      ```
      # Make the effect fail 50% of the time
      %{
        "type" => "ChanceToApply",
        "chance" => 50
      }
      ```
  - Apply Tags
    - For the duration of the effect, tags will be applied to the unit.
  - Target Tag Requirements
    - Limit the effect to only work when the actor has certain tags.

  Note that the Tag components will contain a lot more options down the road,
  such as separating tag requirements for Ongoing/Activation/Removal parts of an effect.
  Also being able to specify a required tag or a tag required to *not* be present.
  """

  use Ecto.Type

  def type(), do: :string

  def cast(%{
        "type" => "ChanceToApply",
        "chance" => chance
      }) do
    if chance > 1 or chance < 0,
      do: :error,
      else:
        {:ok,
         %{
           "type" => "ChanceToApply",
           "chance" => chance
         }}
  end

  def load(string), do: {:ok, component_from_string(string)}

  def dump(component), do: {:ok, component_to_string(component)}

  defp component_to_string(component) do
    case component do
      %{
        "type" => "ChanceToApply",
        "chance" => chance
      } ->
        "ChanceToApply,#{chance}"

      _ ->
        nil
    end
  end

  defp component_from_string(string) when is_binary(string) do
    case String.split(string, ",") do
      ["ChanceToApply", chance] ->
        %{
          type: "ChanceToApply",
          chance: String.to_float(chance)
        }

      _ ->
        nil
    end
  end
end
