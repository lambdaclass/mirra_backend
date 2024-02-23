defmodule GameBackend.Units.Skills.TargetingStrategy do
  @moduledoc """
  The TargetingStrategy type for skills.
  """

  use Ecto.Type

  def type(), do: :string

  def cast("random"), do: {:ok, "random"}
  def cast("nearest"), do: {:ok, "nearest"}
  def cast("furthest"), do: {:ok, "furthest"}
  def cast("min_health"), do: {:ok, "min_health"}
  def cast("max_health"), do: {:ok, "max_health"}
  def cast("min_shield"), do: {:ok, "min_shield"}
  def cast("max_shield"), do: {:ok, "max_shield"}
  def cast("frontline"), do: {:ok, "frontline"}
  def cast("backline"), do: {:ok, "backline"}
  def cast(%{"factions" => factions}), do: {:ok, {"factions", factions}}
  def cast(%{"classes" => classes}), do: {:ok, {"classes", classes}}
  def cast(_), do: :error

  def load(string), do: {:ok, targeting_strategy_from_string(string)}

  def dump(time), do: {:ok, targeting_strategy_to_string(time)}

  defp targeting_strategy_to_string("random"), do: "random"
  defp targeting_strategy_to_string("nearest"), do: "nearest"
  defp targeting_strategy_to_string("furthest"), do: "furthest"
  defp targeting_strategy_to_string("min_health"), do: "min_health"
  defp targeting_strategy_to_string("max_health"), do: "max_health"
  defp targeting_strategy_to_string("min_shield"), do: "min_shield"
  defp targeting_strategy_to_string("max_shield"), do: "max_shield"
  defp targeting_strategy_to_string("frontline"), do: "frontline"
  defp targeting_strategy_to_string("backline"), do: "backline"

  defp targeting_strategy_to_string({"factions", factions}),
    do: "factions,#{Enum.join(factions, ",")}"

  defp targeting_strategy_to_string({"classes", classes}),
    do: "classes,#{Enum.join(classes, ",")}"

  defp targeting_strategy_to_string(_), do: nil

  defp targeting_strategy_from_string("random"), do: "random"
  defp targeting_strategy_from_string("nearest"), do: "nearest"
  defp targeting_strategy_from_string("furthest"), do: "furthest"
  defp targeting_strategy_from_string("min_health"), do: "min_health"
  defp targeting_strategy_from_string("max_health"), do: "max_health"
  defp targeting_strategy_from_string("min_shield"), do: "min_shield"
  defp targeting_strategy_from_string("max_shield"), do: "max_shield"
  defp targeting_strategy_from_string("frontline"), do: "frontline"
  defp targeting_strategy_from_string("backline"), do: "backline"

  defp targeting_strategy_from_string(string) when is_binary(string) do
    case String.split(string, ",") do
      ["factions", factions] ->
        {"factions", factions}

      ["classes", classes] ->
        {"classes", classes}

      _ ->
        nil
    end
  end
end
