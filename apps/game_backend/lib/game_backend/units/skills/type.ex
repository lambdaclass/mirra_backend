defmodule GameBackend.Units.Skills.Type do
  @moduledoc """
  The Type type for skill effects.
  """

  use Ecto.Type

  def type(), do: :string

  def cast("instant"), do: {:ok, "instant"}
  def cast(%{"duration" => duration}), do: {:ok, %{"duration" => duration}}

  def cast(%{
        "interval" => interval,
        "trigger_count" => trigger_count
      }),
      do:
        {:ok,
         %{
           "interval" => interval,
           "trigger_count" => trigger_count
         }}

  def cast(_), do: :error

  def load(string), do: {:ok, time_type_from_string(string)}

  def dump(time), do: {:ok, time_type_to_string(time)}

  defp time_type_to_string(effect_time_type) do
    case effect_time_type do
      "instant" ->
        "instant"

      %{"duration" => duration} ->
        "duration,#{duration}"

      %{
        "interval" => interval,
        "trigger_count" => trigger_count
      } ->
        "periodic,#{interval},#{trigger_count}"

      _ ->
        nil
    end
  end

  defp time_type_from_string("instant"), do: "instant"

  defp time_type_from_string(string) when is_binary(string) do
    case String.split(string, ",") do
      ["duration", duration] ->
        {"duration", %{duration: String.to_integer(duration)}}

      ["periodic", interval, trigger_count] ->
        {"periodic",
         %{
           interval: String.to_integer(interval),
           trigger_count: String.to_integer(trigger_count)
         }}

      _ ->
        nil
    end
  end
end
