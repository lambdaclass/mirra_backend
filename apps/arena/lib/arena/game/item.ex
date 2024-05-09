defmodule Arena.Game.Item do
  @moduledoc """
  Module to handle items logic
  """

  alias Arena.Entities
  alias Arena.Game.Player

  @doc """
  Apply all item mechanics to an entity
  """
  def do_mechanic(game_state, entity, mechanics) when is_map(mechanics) do
    Enum.reduce(mechanics, game_state, fn mechanic, game_state_acc ->
      do_mechanic(game_state_acc, entity, mechanic)
    end)
  end

  @doc """
  Apply create item mechanic to an entity
  """
  def do_mechanic(game_state, entity, {:create_item, mechanic_params}) do
    last_id = game_state.last_id + 1
    entity_player_owner = get_entity_player_owner(game_state, entity)

    bomb_item_params = %{
      name: mechanic_params.name,
      radius: 200.0,
      effects: [],
      on_pickup_effects: %{
        damage: %{
          damage: mechanic_params.damage
        }
      },
      mechanics: []
    }

    bomb_item = Entities.new_item(last_id, entity_player_owner.position, bomb_item_params)

    game_state
    |> put_in([:last_id], last_id)
    |> put_in([:items, bomb_item.id], bomb_item)
  end

  def do_pickup_effect(entity, item, pick_effects) when map_size(pick_effects) == 0 do
    put_in(entity, [:aditional_info, :inventory], item)
  end

  def do_pickup_effect(entity, item, pickup_effects) when is_map(pickup_effects) do
    Enum.reduce(pickup_effects, entity, fn pick_up_effect, entity ->
      do_pickup_effect(entity, item, pick_up_effect)
    end)
  end

  def do_pickup_effect(entity, _item, {:damage, pickup_effect_params}) do
    Player.take_damage(entity, pickup_effect_params.damage)
  end

  defp get_entity_player_owner(_game_state, %{category: :player} = player), do: player

  defp get_entity_player_owner(game_state, %{
         category: :projectile,
         aditional_info: %{owner_id: owner_id}
       }),
       do: get_in(game_state, [:players, owner_id])
end
