defmodule GameBackend.Units.Skills.Effects.Type do
  @moduledoc """
  The Type type for skill effects.
  """

  use Ecto.Type

  def type(), do: :string

  def cast("instant"), do: {:ok, "instant"}
  def cast(%{duration: duration, period: period}), do: {:ok, %{"duration" => duration, "period" => period}}
  def cast(%{period: period}), do: {:ok, %{"period" => period}}
  def cast(_), do: :error

  def load(string), do: {:ok, time_type_from_string(string)}

  def dump(time), do: {:ok, time_type_to_string(time)}

  defp time_type_to_string(effect_time_type) do
    case effect_time_type do
      "instant" ->
        "instant"

      %{"duration" => duration, "period" => period} ->
        "duration,#{duration},#{period}"

      %{"period" => period} ->
        "permanent,#{period}"
    end
  end

  defp time_type_from_string("instant"), do: "instant"

  defp time_type_from_string(string) when is_binary(string) do
    case String.split(string, ",") do
      ["duration", duration, period] ->
        {"duration", %{duration: String.to_integer(duration), period: String.to_integer(period)}}

      ["permanent", period] ->
        {"permanent", %{period: String.to_integer(period)}}

      _ ->
        nil
    end
  end
end
