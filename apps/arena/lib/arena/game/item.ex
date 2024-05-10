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

    new_item_params = %{
      name: mechanic_params.name,
      radius: 200.0,
      effects: [],
      on_pickup_effects: %{
        damage: %{
          damage_type: mechanic_params.damage_type,
          damage_delay_ms: mechanic_params.damage_delay_ms
        },
      },
      mechanics: %{}
    }

    bomb_item = Entities.new_item(last_id, entity_player_owner.position, new_item_params)

    game_state
    |> put_in([:last_id], last_id)
    |> put_in([:items, bomb_item.id], bomb_item)
  end

  def do_pickup_effect(game_state, entity, item, pick_effects) when map_size(pick_effects) == 0 do
    entity = put_in(entity, [:aditional_info, :inventory], item)
    put_in(game_state, [:players, entity.id], entity)
  end

  def do_pickup_effect(game_state, entity, item, pickup_effects) when is_map(pickup_effects) do
    Enum.reduce(pickup_effects, entity, fn pick_up_effect, entity ->
      do_pickup_effect(game_state, entity, item, pick_up_effect)
    end)
  end

  def do_pickup_effect(game_state, entity, _item, {:damage, pickup_effect_params}) do
    maybe_delay_damage(game_state, entity, pickup_effect_params)
  end

  defp maybe_delay_damage(game_state, entity, %{damage_delay_ms: damage_delay_ms} = pickup_effect_params) do
    Enum.reduce(pickup_effect_params.damage_type, game_state, fn damage_type, game_state ->
      Arena.Game.Skill.do_mechanic(game_state, entity, damage_type, %{})
    end)
  end

  defp maybe_delay_damage(game_state, entity, pickup_effect_params) do
    Arena.Game.Skill.do_mechanic(game_state, entity, pickup_effect_params.damage_type, %{})
  end


  defp get_entity_player_owner(_game_state, %{category: :player} = player), do: player

  defp get_entity_player_owner(game_state, %{
         category: :projectile,
         aditional_info: %{owner_id: owner_id}
       }),
       do: get_in(game_state, [:players, owner_id])
end
