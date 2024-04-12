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

  def cast(%{factions: factions}), do: {:ok, %{factions: factions}}
  def cast(%{classes: classes}), do: {:ok, %{classes: classes}}
  def cast(%{lowest: attribute}), do: {:ok, %{lowest: attribute}}
  def cast(%{highest: attribute}), do: {:ok, %{highest: attribute}}

  # Needed for the case in which we decode from the DB (Further explanation in: https://hexdocs.pm/ecto/Ecto.Schema.html#embeds_one/3-encoding-and-decoding)
  def cast(%{"factions" => factions}), do: {:ok, {"factions", factions}}
  def cast(%{"classes" => classes}), do: {:ok, {"classes", classes}}
  def cast(%{"lowest" => attribute}), do: {:ok, %{lowest: attribute}}
  def cast(%{"highest" => attribute}), do: {:ok, %{highest: attribute}}

  def cast(_), do: :error

  # These functions are unused, but need to be implemented to avoid a warning.
  def load(_), do: nil
  def dump(_), do: nil
end
