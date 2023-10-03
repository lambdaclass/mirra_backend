defmodule LambdaGameEngineTest do
  use ExUnit.Case
  doctest LambdaGameEngine

  test "can parse config.json" do
    {:ok, data} =
      Application.app_dir(:lambda_game_engine, "priv/config.json")
      |> File.read()

    assert is_map(LambdaGameEngine.parse_config(data))
  end

  test "can add a player" do
    {:ok, data} =
      Application.app_dir(:lambda_game_engine, "priv/config.json")
      |> File.read()

    config = LambdaGameEngine.parse_config(data)
    game = LambdaGameEngine.engine_new_game(config)

    ## A character that does not exist does nothing and returns `nil`
    assert match?({game, nil}, LambdaGameEngine.add_player(game, "miss-character"))

    character_name = Enum.random(config.characters).name
    {game, player_id1} = LambdaGameEngine.add_player(game, character_name)
    {game, player_id2} = LambdaGameEngine.add_player(game, character_name)
    assert player_id1 == 1
    assert player_id2 == 2
    assert Enum.count(game.players) == 2
  end
end
