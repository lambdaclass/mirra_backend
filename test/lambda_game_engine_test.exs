defmodule LambdaGameEngineTest do
  use ExUnit.Case
  doctest LambdaGameEngine

  setup do
    {:ok, data} =
      Application.app_dir(:dark_worlds_server, "priv/test_config.json")
      |> File.read()

    config = LambdaGameEngine.parse_config(data)
    game = LambdaGameEngine.engine_new_game(config)

    character_name = Enum.random(config.characters).name
    {game, player_id} = LambdaGameEngine.add_player(game, character_name)
    %{game: game, player_id: player_id}
  end

  test "can parse config.json" do
    {:ok, data} =
      Application.app_dir(:dark_worlds_server, "priv/test_config.json")
      |> File.read()

    assert is_map(LambdaGameEngine.parse_config(data))
  end

  test "parsed zone config retains modifications order" do
    {:ok, data} =
      Application.app_dir(:dark_worlds_server, "priv/test_config.json")
      |> File.read()

    config = LambdaGameEngine.parse_config(data)

    ## This asserts are based on how config.json is written so any changes on the
    ## modification stages will likely require a change here
    [zone_modification1, zone_modification2, zone_modification3] = config.game.zone_modifications
    assert zone_modification1.min_radius == 6000
    assert zone_modification2.min_radius == 3000
    assert zone_modification3.min_radius == 100
  end

  test "can add a player" do
    {:ok, data} =
      Application.app_dir(:dark_worlds_server, "priv/test_config.json")
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

  test "picks up loot and use", context do
    game = spawn_specific_loot(context.game, :collision_use)
    [loot] = game.loots

    position = %{x: loot.position.x, y: loot.position.y - 25}
    game = put_in(game, [:players, context.player_id, :position], position)
    game = put_in(game, [:players, context.player_id, :health], 50)
    game = LambdaGameEngine.move_player(game, context.player_id, 90.0)

    assert [] = game.loots
    assert 80 = get_in(game, [:players, context.player_id, :health])
  end

  test "picks up loot, store in inventory, and use", context do
    game = spawn_specific_loot(context.game, :collision_to_inventory)
    [loot] = game.loots

    position = %{x: loot.position.x, y: loot.position.y - 25}
    game = put_in(game, [:players, context.player_id, :position], position)
    game = put_in(game, [:players, context.player_id, :health], 50)
    game = LambdaGameEngine.move_player(game, context.player_id, 90.0)
    assert [] = game.loots

    player = get_in(game, [:players, context.player_id])
    assert [^loot] = player.inventory
    assert 50 = player.health

    game = LambdaGameEngine.activate_inventory(game, context.player_id, 0)
    player = get_in(game, [:players, context.player_id])
    assert [nil] = player.inventory
    assert 80 = player.health
  end

  test "inventory is capped", context do
    game =
      spawn_specific_loot(context.game, :collision_to_inventory)
      |> spawn_specific_loot(:collision_to_inventory)

    [loot1, loot2] = game.loots

    position = %{x: loot1.position.x, y: loot1.position.y - 25}
    game = put_in(game, [:players, context.player_id, :position], position)
    game = put_in(game, [:players, context.player_id, :health], 50)
    game = LambdaGameEngine.move_player(game, context.player_id, 90.0)
    assert [^loot2] = game.loots

    player = get_in(game, [:players, context.player_id])
    assert [^loot1] = player.inventory

    position = %{x: loot2.position.x, y: loot2.position.y - 25}
    game = put_in(game, [:players, context.player_id, :position], position)
    game = put_in(game, [:players, context.player_id, :health], 50)
    game = LambdaGameEngine.move_player(game, context.player_id, 90.0)
    assert [^loot2] = game.loots
    assert [^loot1] = player.inventory
  end

  defp spawn_specific_loot(game_state, loot_mechanic) do
    {new_game_state, loot_id} = LambdaGameEngine.spawn_random_loot(game_state)

    case Enum.find(new_game_state.loots, fn loot -> loot.id == loot_id end) do
      %{pickup_mechanic: ^loot_mechanic} -> new_game_state
      _ -> spawn_specific_loot(game_state, loot_mechanic)
    end
  end
end
