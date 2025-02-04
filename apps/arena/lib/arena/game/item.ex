defmodule Arena.Game.Item do
  @moduledoc """
  Module to handle items logic
  """

  alias Arena.Entities
  alias Arena.Game.Player
  alias Arena.Game.Skill

  @doc """
  Apply all item mechanics to an entity
  """
  def do_mechanics(game_state, entity, mechanics) do
    Enum.reduce(mechanics, game_state, fn mechanic, game_state_acc ->
      do_mechanic(game_state_acc, entity, mechanic)
    end)
  end

  @doc """
  Apply an item mechanic to an entity, depending on the mechanic type.
  """
  def do_mechanic(game_state, entity, %{type: "spawn_bomb"} = bomb_params) do
    last_id = game_state.last_id + 1

    now = System.monotonic_time(:millisecond)

    new_trap =
      Entities.new_trap(last_id, entity.id, entity.position, bomb_params)
      |> Map.put(:prepare_at, now + bomb_params.preparation_delay_ms)

    game_state
    |> put_in([:last_id], last_id)
    |> put_in([:traps, new_trap.id], new_trap)
  end

  def do_mechanic(game_state, entity, %{type: "heal"} = item_params) do
    player = Player.add_health(entity, item_params.amount)

    put_in(game_state, [:players, player.id], player)
  end

  def do_mechanic(game_state, entity, %{type: "circle_hit"} = item_params) do
    Skill.do_mechanic(game_state, entity, item_params, %{})
  end

  def do_mechanic(game_state, _entity, _mechanic) do
    game_state
  end
end
