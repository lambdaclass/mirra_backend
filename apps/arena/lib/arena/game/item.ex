defmodule Arena.Game.Item do
  @moduledoc """
  Module to handle items logic
  """

  alias Arena.Entities

  @doc """
  Apply all item mechanics to an entity
  """
  def do_mechanic(game_state, entity, mechanics) when is_map(mechanics) do
    Enum.reduce(mechanics, game_state, fn mechanic, game_state_acc ->
      do_mechanic(game_state_acc, entity, mechanic)
    end)
  end

  def do_mechanic(game_state, entity, {:create_item, mechanic_params}) do
    last_id = game_state.last_id + 1
    entity_player_owner = get_entity_player_owner(game_state, entity)

    new_item_params = %{
      name: mechanic_params.name,
      radius: mechanic_params.radius,
      effects: mechanic_params.effects,
      pickable: mechanic_params.pickable,
      on_pickup_effects: mechanic_params.on_pickup_effects,
      mechanics: mechanic_params.mechanics
    }

    new_item = Entities.new_item(last_id, entity_player_owner.position, new_item_params)

    game_state
    |> put_in([:last_id], last_id)
    |> put_in([:items, new_item.id], new_item)
  end

  @doc """
  Apply all item pickup effects to an entity
  """
  def do_pickup_effect(game_state, _entity, _item, pick_effects) when map_size(pick_effects) == 0, do: game_state

  def do_pickup_effect(game_state, entity, item, pickup_effects) when is_map(pickup_effects) do
    entity =
      Enum.reduce(pickup_effects, entity, fn pick_up_effect, entity ->
        do_pickup_effect(entity, item, pick_up_effect)
      end)

    put_in(game_state, [:players, entity.id], entity)
  end

  def do_pickup_effect(entity, _item, {:damage, pickup_effect_params}) do
    maybe_delay_damage(entity, pickup_effect_params)
    entity
  end

  defp maybe_delay_damage(entity, %{damage_delay_ms: damage_delay_ms} = pickup_effect_params) do
    Process.send_after(self(), {:apply_item_damage, entity, pickup_effect_params}, damage_delay_ms)
  end

  defp maybe_delay_damage(entity, pickup_effect_params) do
    send(self(), {:apply_item_damage, entity, pickup_effect_params})
  end

  defp get_entity_player_owner(_game_state, %{category: :player} = player), do: player

  defp get_entity_player_owner(game_state, %{
         category: :projectile,
         aditional_info: %{owner_id: owner_id}
       }),
       do: get_in(game_state, [:players, owner_id])
end
