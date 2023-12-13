defmodule DarkWorldsServer.TimeType do
  use Ecto.Type

  def type, do: :string

  def cast("Instant"), do: {:ok, "Instant"}
  def cast("Permanent"), do: {:ok, "Permanent"}
  def cast(%{"duration_ms" => duration_ms}) when is_integer(duration_ms), do: {:ok, %{"duration_ms" => duration_ms}}

  def cast(%{
        "instant_applicaiton" => instant_applicaiton,
        "interval_ms" => interval_ms,
        "trigger_count" => trigger_count
      }),
      do:
        {:ok,
         %{"instant_applicaiton" => instant_applicaiton, "interval_ms" => interval_ms, "trigger_count" => trigger_count}}

  def cast(_), do: :error

  def load("Instant"), do: {:ok, "Instant"}
  def load("Permanent"), do: {:ok, "Permanent"}
  def load(%{"duration_ms" => duration_ms}), do: {:ok, %{"duration_ms" => duration_ms}}

  def load(%{
        "instant_applicaiton" => instant_applicaiton,
        "interval_ms" => interval_ms,
        "trigger_count" => trigger_count
      }),
      do:
        {:ok,
         %{"instant_applicaiton" => instant_applicaiton, "interval_ms" => interval_ms, "trigger_count" => trigger_count}}

  def dump("Instant"), do: {:ok, "Instant"}
  def dump("Permanent"), do: {:ok, "Permanent"}
  def dump(%{"duration_ms" => duration_ms}), do: {:ok, %{"duration_ms" => duration_ms}}

  def dump(%{
        "instant_application" => instant_application,
        "interval_ms" => interval_ms,
        "trigger_count" => trigger_count
      }),
      do:
        {:ok,
         %{"instant_application" => instant_application, "interval_ms" => interval_ms, "trigger_count" => trigger_count}}

  def to_string(effect_time_type) do
    case effect_time_type do
      "Instant" ->
        "Instant"

      "Permanent" ->
        "Permanent"

      %{"duration_ms" => duration_ms} ->
        "Duration: #{duration_ms} ms"

      %{
        "instant_application" => instant_application,
        "interval_ms" => interval_ms,
        "trigger_count" => trigger_count
      } ->
        "Periodic: #{instant_application}, Interval: #{interval_ms} ms, Triggers: #{trigger_count}"

      _ ->
        nil
    end
  end

  def from_string("Instant"), do: "Instant"
  def from_string("Permanent"), do: "Permanent"

  def from_string(string) when is_binary(string) do
    case String.split(string, ~r/:\s+/) do
      ["Duration", duration_ms] ->
        %{"duration_ms" => String.to_integer(duration_ms)}

      ["Periodic", instant_application, interval_ms, triggers] ->
        %{
          "instant_application" => string_to_boolean(instant_application),
          "interval_ms" => String.to_integer(interval_ms),
          "trigger_count" => String.to_integer(triggers)
        }

      _ ->
        "Invalid"
    end
  end

  defp string_to_boolean("true"), do: true
  defp string_to_boolean("True"), do: true
  defp string_to_boolean("false"), do: false
  defp string_to_boolean("False"), do: false
end
