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

  defp get_entity_player_owner(_game_state, %{category: :player} = player), do: player

  defp get_entity_player_owner(game_state, %{
         category: :projectile,
         aditional_info: %{owner_id: owner_id}
       }),
       do: get_in(game_state, [:players, owner_id])
end
