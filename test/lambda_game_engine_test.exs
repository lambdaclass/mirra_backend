defmodule LambdaGameEngineTest do
  use ExUnit.Case
  doctest LambdaGameEngine

  test "can parse config.json" do
    {:ok, data} =
      Application.app_dir(:lambda_game_engine, "priv/config.json")
      |> File.read()

    assert is_map(LambdaGameEngine.parse_config(data))
  end
end
