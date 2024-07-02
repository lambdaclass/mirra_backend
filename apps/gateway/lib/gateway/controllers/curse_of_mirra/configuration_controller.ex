defmodule Gateway.Controllers.CurseOfMirra.ConfigurationController do
  @moduledoc """
  Controller for Curse of Mirra Configurations
  """
  use Gateway, :controller
  alias GameBackend.Configuration
  alias GameBackend.Utils
  alias GameBackend.Items

  action_fallback Gateway.Controllers.FallbackController

  def get_characters_configuration(conn, _params) do
    case GameBackend.Units.Characters.get_curse_characters() do
      [] ->
        {:error, :not_found}

      characters ->
        send_resp(
          conn,
          200,
          Jason.encode!(
            Utils.transform_to_map_from_ecto_struct(characters, [
              :basic_skill,
              :ultimate_skill
            ])
          )
        )
    end
  end

  def get_game_configuration(conn, _params) do
    game_configuration = Configuration.get_latest_game_configuration()
    game_configuration = Utils.transform_to_map_from_ecto_struct(game_configuration)
    send_resp(conn, 200, Jason.encode!(game_configuration))
  end

  def get_consumable_items_configuration(conn, _params) do
    consumable_items = Items.list_consumable_items()
    consumable_items = Utils.transform_to_map_from_ecto_struct(consumable_items)
    send_resp(conn, 200, Jason.encode!(consumable_items))
  end
end
