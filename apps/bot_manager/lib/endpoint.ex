defmodule BotManager.Endpoint do
  @moduledoc """
  endpoints :
  - /join/:game_pid/:player_id/:character_name (GET)
  """

  use Plug.Router
  # This module is a Plug, that also implements it's own plug pipeline, below:

  # Using Plug.Logger for logging request information
  plug(Plug.Logger)

  # responsible for matching routes
  plug(:match)

  # Using Poison for JSON decoding
  # Note, order of plugs is important, by placing this _after_ the 'match' plug,
  # we will only parse the request AFTER there is a route match.
  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  # responsible for dispatching responses
  plug(:dispatch)

  get "/join/:game_id/:bot_client" do
    bot_pid = BotManager.BotSupervisor.add_bot_to_game(conn.params)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(bot_pid |> :erlang.term_to_binary() |> Base58.encode()))
  end

  # A catchall route, 'match' will match no matter the request method,
  # so a response is always returned, even if there is no route to match.
  match _ do
    send_resp(conn, 404, "Unknown request :( !")
  end
end
