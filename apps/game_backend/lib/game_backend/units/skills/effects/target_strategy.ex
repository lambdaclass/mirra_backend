defmodule GameBackend.Units.Skills.Effects.TargetStrategy do
  @moduledoc """
  The TargetStrategy type for skills.
  """

  use Ecto.Type

  def type(), do: :string

  def cast("all"), do: {:ok, "all"}
  def cast("self"), do: {:ok, "self"}
  def cast("random"), do: {:ok, "random"}
  def cast("nearest"), do: {:ok, "nearest"}
  def cast("furthest"), do: {:ok, "furthest"}
  def cast("frontline"), do: {:ok, "frontline"}
  def cast("backline"), do: {:ok, "backline"}
  def cast("min"), do: {:ok, "min"}
  def cast("max"), do: {:ok, "max"}
  def cast(%{"factions" => factions}), do: {:ok, {"factions", factions}}
  def cast(%{"classes" => classes}), do: {:ok, {"classes", classes}}
  def cast(%{"lowest" => attribute}), do: {:ok, {"lowest", attribute}}
  def cast(%{"highest" => attribute}), do: {:ok, {"highest", attribute}}
  def cast(_), do: :error

  def load(string), do: {:ok, target_strategy_from_string(string)}

  def dump(strategy), do: {:ok, target_strategy_to_string(strategy)}

  defp target_strategy_to_string("random"), do: "random"
  defp target_strategy_to_string("nearest"), do: "nearest"
  defp target_strategy_to_string("furthest"), do: "furthest"
  defp target_strategy_to_string("frontline"), do: "frontline"
  defp target_strategy_to_string("backline"), do: "backline"

  defp target_strategy_to_string({"factions", factions}),
    do: "factions,#{Enum.join(factions, ",")}"

  defp target_strategy_to_string({"classes", classes}),
    do: "classes,#{Enum.join(classes, ",")}"

  defp target_strategy_to_string({"lowest", attribute}),
    do: "lowest,#{attribute}"

  defp target_strategy_to_string({"highest", attribute}),
    do: "highest,#{attribute}"

  defp target_strategy_to_string(_), do: nil

  defp target_strategy_from_string("random"), do: "random"
  defp target_strategy_from_string("nearest"), do: "nearest"
  defp target_strategy_from_string("furthest"), do: "furthest"
  defp target_strategy_from_string("frontline"), do: "frontline"
  defp target_strategy_from_string("backline"), do: "backline"

  defp target_strategy_from_string(string) when is_binary(string) do
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
