defmodule GameBackendTest do
  alias DarkWorldsServer.Communication
  use ExUnit.Case
  doctest GameBackend

  setup do
    {:ok, data} =
      Application.app_dir(:dark_worlds_server, "priv/test_config.json")
      |> File.read()

    config = GameBackend.parse_config(data)
    game = GameBackend.new_game(config)

    {:ok, {game, player_id}} = GameBackend.add_player(game, "test_character")
    %{game: game, player_id: player_id}
  end

  test "can parse config.json" do
    {:ok, data} =
      Application.app_dir(:dark_worlds_server, "priv/test_config.json")
      |> File.read()

    assert is_map(GameBackend.parse_config(data))
  end

  test "parsed zone config retains modifications order" do
    {:ok, data} =
      Application.app_dir(:dark_worlds_server, "priv/test_config.json")
      |> File.read()

    config = GameBackend.parse_config(data)

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

    config = GameBackend.parse_config(data)
    game = GameBackend.new_game(config)

    ## A character that does not exist does nothing and returns `:character_not_found`
    assert match?({:error, :character_not_found}, GameBackend.add_player(game, "miss-character"))

    character_name = Enum.random(config.characters).name
    {:ok, {game, player_id1}} = GameBackend.add_player(game, character_name)
    {:ok, {game, player_id2}} = GameBackend.add_player(game, character_name)
    assert player_id1 == 1
    assert player_id2 == 2
    assert Enum.count(game.players) == 2
  end

  test "can apply effects on player", context do
    player_pre_effect = context.game.players[context.player_id]
    game = GameBackend.apply_effect(context.game, context.player_id, "test_effect")
    player_post_effect = game.players[context.player_id]

    assert player_pre_effect.speed < player_post_effect.speed
  end

  test "spawns a loot randomly", context do
    {game, loot_id} = GameBackend.spawn_random_loot(context.game)
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
    game = GameBackend.move_player(game, context.player_id, 90.0)

    assert [] = game.loots
    assert 80 = get_in(game, [:players, context.player_id, :health])
  end

  test "picks up loot, store in inventory, and use", context do
    game = spawn_specific_loot(context.game, :collision_to_inventory)
    [loot] = game.loots

    position = %{x: loot.position.x, y: loot.position.y - 25}
    game = put_in(game, [:players, context.player_id, :position], position)
    game = put_in(game, [:players, context.player_id, :health], 50)
    game = GameBackend.move_player(game, context.player_id, 90.0)
    assert [] = game.loots

    player = get_in(game, [:players, context.player_id])
    assert [^loot] = player.inventory
    assert 50 = player.health

    game = GameBackend.activate_inventory(game, context.player_id, 0)
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
    game = GameBackend.move_player(game, context.player_id, 90.0)
    assert [^loot2] = game.loots

    player = get_in(game, [:players, context.player_id])
    assert [^loot1] = player.inventory

    position = %{x: loot2.position.x, y: loot2.position.y - 25}
    game = put_in(game, [:players, context.player_id, :position], position)
    game = put_in(game, [:players, context.player_id, :health], 50)
    game = GameBackend.move_player(game, context.player_id, 90.0)
    assert [^loot2] = game.loots
    assert [^loot1] = player.inventory
  end

  test "Cooldowns are removed", context do
    skill_params = %{"direction_angle" => "90.0", "auto_aim" => "false"}
    game = GameBackend.activate_skill(context.game, context.player_id, "1", skill_params)
    %{"1" => cooldown} = game.players[context.player_id].cooldowns

    elapsed_time_ms = div(cooldown, 2)
    game = GameBackend.game_tick(game, elapsed_time_ms)
    %{"1" => cooldown2} = game.players[context.player_id].cooldowns
    assert cooldown2 == cooldown - elapsed_time_ms

    elapsed_time_ms = cooldown * 2
    game = GameBackend.game_tick(game, elapsed_time_ms)
    assert %{} = game.players[context.player_id].cooldowns
  end

  test "Game state is encodable", context do
    game_state =
      spawn_specific_loot(context.game, :collision_to_inventory)
      |> spawn_specific_loot(:collision_to_inventory)

    [inventory_item | _] = game_state.loots

    position = %{x: inventory_item.position.x, y: inventory_item.position.y - 25}
    game_state = put_in(game_state, [:players, context.player_id, :position], position)
    game_state = put_in(game_state, [:players, context.player_id, :health], 50)
    game_state = GameBackend.move_player(game_state, context.player_id, 90.0)
    game_state = GameBackend.game_tick(game_state, 5000)

    Communication.game_update!(game_state, now_timestamp(), now_timestamp())


    skill_params = %{"direction_angle" => "90.0", "auto_aim" => "false"}
    game_state = GameBackend.activate_skill(game_state, context.player_id, "slingshot", skill_params)
    game_state = GameBackend.game_tick(game_state, 500)

    game_state = GameBackend.activate_skill(game_state, context.player_id, "6", skill_params)
    Communication.game_update!(game_state, now_timestamp(), now_timestamp())
  end

  defp spawn_specific_loot(game_state, loot_mechanic) do
    spawn_specific_loot(game_state, loot_mechanic, 100)
  end

  defp spawn_specific_loot(_game_state, loot_mechanic, 0) do
    raise "error spawn_specific_loot/2 could spawn desired loot #{loot_mechanic}"
  end

  defp spawn_specific_loot(game_state, loot_mechanic, attempts) do
    {new_game_state, loot_id} = GameBackend.spawn_random_loot(game_state)

    case Enum.find(new_game_state.loots, fn loot -> loot.id == loot_id end) do
      %{pickup_mechanic: ^loot_mechanic} -> new_game_state
      _ -> spawn_specific_loot(game_state, loot_mechanic, attempts-1)
    end
  end

  defp now_timestamp() do
    DateTime.utc_now() |> DateTime.to_unix(:millisecond)
  end
end
