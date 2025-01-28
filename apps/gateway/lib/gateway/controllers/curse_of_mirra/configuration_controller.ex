defmodule Gateway.Controllers.CurseOfMirra.ConfigurationController do
  @moduledoc """
  Controller for Curse of Mirra Configurations
  """
  use Gateway, :controller
  alias GameBackend.Configuration
  alias GameBackend.Items
  alias GameBackend.Units.Characters

  action_fallback Gateway.Controllers.FallbackController

  def get_current_configuration(conn, _params) do
    version = Configuration.get_current_version()

    config =
      Jason.encode!(%{
        characters: encode_characters(version.characters),
        game: version.game_configuration,
        items: encode_items(version.consumable_items |> Enum.filter(fn ci -> ci.active end)),
        map: version.map_configurations
      })

    send_resp(conn, 200, config)
  end

  def get_characters_configuration(conn, _params) do
    version = Configuration.get_current_version()

    case Characters.get_curse_characters_by_version(version.id) do
      [] ->
        {:error, :not_found}

      characters ->
        send_resp(
          conn,
          200,
          Jason.encode!(encode_characters(characters))
        )
    end
  end

  @spec get_game_configuration(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def get_game_configuration(conn, _params) do
    game_configuration = Configuration.get_latest_game_configuration()
    send_resp(conn, 200, Jason.encode!(game_configuration))
  end

  def get_map_configurations(conn, _params) do
    version = Configuration.get_current_version()
    map_configuration = Configuration.list_map_configurations_by_version(version.id)
    send_resp(conn, 200, Jason.encode!(map_configuration))
  end

  def get_consumable_items_configuration(conn, _params) do
    version = Configuration.get_current_version()
    consumable_items = Items.list_consumable_items_by_version(version.id) |> Enum.filter(& &1.active)
    send_resp(conn, 200, Jason.encode!(consumable_items))
  end

  def get_game_mode_configuration(conn, %{"name" => name, "type" => type}) do
    case Configuration.get_game_mode_configuration_by_name_and_type(name, type) do
      nil ->
        send_resp(conn, 404, "Game mode not found")

      game_mode ->
        send_resp(conn, 200, Jason.encode!(game_mode))
    end
  end

  defp encode_characters(characters) when is_list(characters) do
    Enum.map(characters, fn character ->
      character
      |> Map.put(:basic_skill, encode_skill(character.basic_skill))
      |> Map.put(:ultimate_skill, encode_skill(character.ultimate_skill))
      |> Map.put(:dash_skill, encode_skill(character.dash_skill))
      |> ecto_struct_to_map()
    end)
  end

  defp encode_items(items) do
    Enum.map(items, fn item ->
      item
      |> encode_item()
    end)
  end

  defp encode_item(item) do
    item
    |> Map.put(:mechanics, encode_mechanics(item.mechanics))
    |> ecto_struct_to_map()
  end

  defp encode_skill(nil) do
    nil
  end

  defp encode_skill(skill) do
    skill =
      GameBackend.Repo.preload(skill,
        next_skill: [mechanics: [:on_arrival_mechanic, :on_explode_mechanics, :parent_mechanic]]
      )

    skill
    |> Map.put(:next_skill, encode_skill(skill.next_skill))
    |> Map.put(:mechanics, encode_mechanics(skill.mechanics))
    |> ecto_struct_to_map()
    |> Map.drop([:buff])
  end

  defp encode_mechanics(mechanics) when is_list(mechanics) do
    Enum.map(mechanics, &encode_mechanic/1)
  end

  defp encode_mechanic(nil) do
    nil
  end

  defp encode_mechanic(mechanic) do
    # This is done to avoid the infinite nested mechanics loop
    # Once we enter on a mechanic, we don't want to go deeper (yet).
    on_explode_mechanics =
      Enum.map(mechanic.on_explode_mechanics, fn explode_mechanic ->
        explode_mechanic
        |> Map.put(:on_arrival_mechanic, nil)
        |> Map.put(:on_explode_mechanics, [])
        |> Map.put(:parent_mechanic, nil)
      end)

    on_arrival_mechanic =
      if mechanic.on_arrival_mechanic do
        mechanic.on_arrival_mechanic
        |> Map.put(:on_arrival_mechanic, nil)
        |> Map.put(:on_explode_mechanics, [])
        |> Map.put(:parent_mechanic, nil)
      else
        nil
      end

    parent_mechanic =
      if mechanic.parent_mechanic do
        mechanic.parent_mechanic
        |> Map.put(:on_arrival_mechanic, nil)
        |> Map.put(:on_explode_mechanics, [])
        |> Map.put(:parent_mechanic, nil)
      else
        nil
      end

    mechanic
    |> Map.put(:on_arrival_mechanic, mechanic.on_arrival_mechanic_id && encode_mechanic(on_arrival_mechanic))
    |> Map.put(:on_explode_mechanics, encode_mechanics(on_explode_mechanics))
    |> Map.put(:parent_mechanic, encode_mechanic(parent_mechanic))
    |> ecto_struct_to_map()
    |> Map.drop([:skill, :consumable_item, :apply_effects_to, :passive_effects])
  end

  defp ecto_struct_to_map(ecto_struct) when is_struct(ecto_struct) do
    ecto_struct
    |> Map.from_struct()
    |> Map.drop([
      :__meta__,
      :__struct__,
      :inserted_at,
      :updated_at,
      :id,
      :version
    ])
  end
end
