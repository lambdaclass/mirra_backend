defmodule LambdaGameEngineTest do
  use ExUnit.Case
  doctest LambdaGameEngine

  setup do
    {:ok, data} =
      Application.app_dir(:lambda_game_engine, "priv/config.json")
      |> File.read()

    config = LambdaGameEngine.parse_config(data)
    game = LambdaGameEngine.engine_new_game(config)

    character_name = Enum.random(config.characters).name
    {game, player_id} = LambdaGameEngine.add_player(game, character_name)
    %{game: game, player_id: player_id}
  end

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

  test "can apply effects on player", context do
    player_pre_effect = context.game.players[context.player_id]
    game = LambdaGameEngine.apply_effect(context.game, context.player_id, "test_effect")
    player_post_effect = game.players[context.player_id]

    assert player_pre_effect.speed < player_post_effect.speed
  end

  test "spawns a loot randomly", context do
    {game, loot_id} = LambdaGameEngine.spawn_random_loot(context.game)
    [loot] = game.loots

    assert not is_nil(loot_id)
    assert loot.id == loot_id
  end

  test "moving picks up loot", context do
    {game, _loot_id} = LambdaGameEngine.spawn_random_loot(context.game)
    [loot] = game.loots

    position = %{x: loot.position.x, y: loot.position.y - 25}
    game = put_in(game, [:players, context.player_id, :position], position)
    game = put_in(game, [:players, context.player_id, :health], 50)
    game = LambdaGameEngine.move_player(game, context.player_id, 90.0)

    assert [] = game.loots
    assert 80 = get_in(game, [:players, context.player_id, :health])
  end
end
