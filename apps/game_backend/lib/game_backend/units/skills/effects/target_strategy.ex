defmodule GameBackend.Units.Skills.Effects.TargetStrategy do
  @moduledoc """
  The TargetStrategy type for skills.
  """

  use Ecto.Type

  def type(), do: :string

  # TODO: replace random for the corresponding target strategy name (CHoM #325)
  def cast("all"), do: {:ok, "random"}
  def cast("self"), do: {:ok, "random"}
  def cast("random"), do: {:ok, "random"}
  def cast("nearest"), do: {:ok, "random"}
  def cast("furthest"), do: {:ok, "random"}
  def cast("frontline"), do: {:ok, "random"}
  def cast("backline"), do: {:ok, "random"}
  def cast("min"), do: {:ok, "random"}
  def cast("max"), do: {:ok, "random"}
  def cast(%{"factions" => factions}), do: {:ok, {"factions", factions}}
  def cast(%{"classes" => classes}), do: {:ok, {"classes", classes}}
  def cast(%{"lowest" => attribute}), do: {:ok, {"lowest", attribute}}
  def cast(%{"highest" => attribute}), do: {:ok, {"highest", attribute}}
  def cast(_), do: :error

  def load(string), do: {:ok, target_strategy_from_string(string)}

  def dump(strategy), do: {:ok, target_strategy_to_string(strategy)}

  defp target_strategy_to_string("all"), do: "random"
  defp target_strategy_to_string("self"), do: "random"
  defp target_strategy_to_string("random"), do: "random"
  defp target_strategy_to_string("nearest"), do: "random"
  defp target_strategy_to_string("furthest"), do: "random"
  defp target_strategy_to_string("frontline"), do: "random"
  defp target_strategy_to_string("backline"), do: "random"

  defp target_strategy_to_string({"factions", factions}),
    do: "factions,#{Enum.join(factions, ",")}"

  defp target_strategy_to_string({"classes", classes}),
    do: "classes,#{Enum.join(classes, ",")}"

  defp target_strategy_to_string({"lowest", attribute}),
    do: "lowest,#{attribute}"

  defp target_strategy_to_string({"highest", attribute}),
    do: "highest,#{attribute}"

  defp target_strategy_to_string(_), do: nil

  defp target_strategy_from_string("all"), do: "random"
  defp target_strategy_from_string("self"), do: "random"
  defp target_strategy_from_string("random"), do: "random"
  defp target_strategy_from_string("nearest"), do: "random"
  defp target_strategy_from_string("furthest"), do: "random"
  defp target_strategy_from_string("frontline"), do: "random"
  defp target_strategy_from_string("backline"), do: "random"

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
