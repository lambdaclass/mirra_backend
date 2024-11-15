defmodule Arena.Utils do
  @moduledoc """
  Utils module.
  It contains utility functions like math functions.
  """

  # The available names for bots to enter a match, we should change this in the future
  @bot_names [
    "TheBlackSwordman",
    "SlashJava",
    "SteelBallRun",
    "Jeff",
    "Messi",
    "Stone Ocean",
    "Jeepers Creepers",
    "Bob",
    "El javo",
    "Alberso",
    "Thomas",
    "Timmy",
    "Pablito",
    "Nicolino",
    "Cangrejo",
    "Mansito"
  ]

  def normalize(%{x: 0, y: 0}) do
    %{x: 0, y: 0}
  end

  def normalize(%{x: x, y: y}) do
    length = :math.sqrt(x * x + y * y)
    %{x: x / length, y: y / length}
  end

  def increase_value_by_base_percentage(current_value, base_value, amount) when is_integer(current_value) do
    (current_value + base_value * amount)
    |> round()
  end

  def increase_value_by_base_percentage(current_value, base_value, amount) do
    current_value + base_value * amount
  end

  def get_bot_connection_url(game_id, bot_client) do
    server_url = System.get_env("PHX_HOST") || "localhost"
    bot_manager_host = System.get_env("BOT_MANAGER_HOST", "localhost:4003")
    protocol = get_correct_protocol(bot_manager_host)

    "#{protocol}#{bot_manager_host}/join/#{server_url}/#{game_id}/#{bot_client}"
  end

  def bot_names() do
    @bot_names
  end

  defp get_correct_protocol("localhost" <> _host), do: "http://"
  defp get_correct_protocol(_host), do: "https://"
end
