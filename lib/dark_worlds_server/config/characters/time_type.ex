defmodule DarkWorldsServer.Config.Characters.TimeType do
  use Ecto.Type

  def type(), do: :string

  def cast(:instant), do: {:ok, "Instant"}
  def cast(:permanent), do: {:ok, "Permanent"}
  def cast(%{duration_ms: duration_ms}), do: {:ok, %{"duration_ms" => duration_ms}}

  def cast(%{
        instant_application: instant_application,
        interval_ms: interval_ms,
        trigger_count: trigger_count
      }),
      do:
        {:ok,
         %{"instant_application" => instant_application, "interval_ms" => interval_ms, "trigger_count" => trigger_count}}

  def cast(_), do: :error

  def load(string), do: {:ok, time_type_from_string(string)}

  def dump(time), do: {:ok, time_type_to_string(time)}

  defp time_type_to_string(effect_time_type) do
    case effect_time_type do
      "Instant" ->
        "Instant"

      "Permanent" ->
        "Permanent"

      %{"duration_ms" => duration_ms} ->
        "Duration,#{duration_ms}"

      %{
        "instant_application" => instant_application,
        "interval_ms" => interval_ms,
        "trigger_count" => trigger_count
      } ->
        "Periodic,#{instant_application},#{interval_ms},#{trigger_count}"

      _ ->
        nil
    end
  end

  defp time_type_from_string("Instant"), do: :instant
  defp time_type_from_string("Permanent"), do: :permanent

  defp time_type_from_string(string) when is_binary(string) do
    case String.split(string, ",") do
      ["Duration", duration_ms] ->
        {:duration, %{duration_ms: String.to_integer(duration_ms)}}

      ["Periodic", instant_application, interval_ms, triggers] ->
        {:periodic,
         %{
           instant_application: string_to_boolean(instant_application),
           interval_ms: String.to_integer(interval_ms),
           trigger_count: String.to_integer(triggers),
           time_since_last_trigger: 0
         }}

      _ ->
        "Invalid"
    end
  end

  defp string_to_boolean("true"), do: true
  defp string_to_boolean("True"), do: true
  defp string_to_boolean("false"), do: false
  defp string_to_boolean("False"), do: false
end
