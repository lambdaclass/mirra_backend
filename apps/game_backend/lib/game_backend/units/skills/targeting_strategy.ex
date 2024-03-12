defmodule GameBackend.Units.Skills.TargetingStrategy do
  @moduledoc """
  The TargetingStrategy type for skills.
  """

  use Ecto.Type

  def type(), do: :string

  def cast("random"), do: {:ok, "random"}
  def cast("nearest"), do: {:ok, "nearest"}
  def cast("furthest"), do: {:ok, "furthest"}
  def cast("frontline"), do: {:ok, "frontline"}
  def cast("backline"), do: {:ok, "backline"}
  def cast(%{"factions" => factions}), do: {:ok, {"factions", factions}}
  def cast(%{"classes" => classes}), do: {:ok, {"classes", classes}}
  def cast({"lowest", attribute}), do: {:ok, {"lowest", attribute}}
  def cast({"highest", attribute}), do: {:ok, {"highest", attribute}}
  def cast(_), do: :error

  def load(string), do: {:ok, targeting_strategy_from_string(string)}

  def dump(strategy), do: {:ok, targeting_strategy_to_string(strategy)}

  defp targeting_strategy_to_string("random"), do: "random"
  defp targeting_strategy_to_string("nearest"), do: "nearest"
  defp targeting_strategy_to_string("furthest"), do: "furthest"
  defp targeting_strategy_to_string("frontline"), do: "frontline"
  defp targeting_strategy_to_string("backline"), do: "backline"

  defp targeting_strategy_to_string({"factions", factions}),
    do: "factions,#{Enum.join(factions, ",")}"

  defp targeting_strategy_to_string({"classes", classes}),
    do: "classes,#{Enum.join(classes, ",")}"

  defp targeting_strategy_to_string({"lowest", attribute}),
    do: "lowest,#{attribute}"

  defp targeting_strategy_to_string({"highest", attribute}),
    do: "highest,#{attribute}"

  defp targeting_strategy_to_string(_), do: nil

  defp targeting_strategy_from_string("random"), do: "random"
  defp targeting_strategy_from_string("nearest"), do: "nearest"
  defp targeting_strategy_from_string("furthest"), do: "furthest"
  defp targeting_strategy_from_string("frontline"), do: "frontline"
  defp targeting_strategy_from_string("backline"), do: "backline"

  defp targeting_strategy_from_string(string) when is_binary(string) do
    case String.split(string, ",") do
      ["factions", factions] ->
        {"factions", factions}

      ["classes", classes] ->
        {"classes", classes}

      ["lowest", attribute] ->
        {"lowest", attribute}

      ["highest", attribute] ->
        {"highest", attribute}

      _ ->
        nil
    end
  end
end
