defmodule Gateway.ChampionsSocketHandler do
  @moduledoc """
  Module that handles cowboy websocket requests
  """

  require Logger
  alias Gateway.Serialization.WebSocketResponse
  alias Champions.{Battle, Campaigns, Items, Users, Units}

  alias Gateway.Serialization.{
    WebSocketRequest,
    GetUser,
    GetUserByUsername,
    CreateUser,
    GetCampaigns,
    GetCampaign,
    GetLevel,
    FightLevel,
    SelectUnit,
    UnselectUnit,
    EquipItem,
    UnequipItem,
    GetItem,
    LevelUpItem
  }

  @behaviour :cowboy_websocket

  @impl true
  def init(req, _opts) do
    client_id = :cowboy_req.binding(:client_id, req)

    {:cowboy_websocket, req, %{client_id: client_id}}
  end

  @impl true
  def websocket_init(state) do
    Logger.info("Websocket INIT called")

    {:reply, {:pong, ""}, state}
  end

  def websocket_handle({:binary, message}, state) do
    with %WebSocketRequest{request_type: {_type, request}} <- WebSocketRequest.decode(message) do
      response =
        case request do
          %GetUser{user_id: user_id} ->
            {:user, Users.get_user(user_id)}

          %GetUserByUsername{username: username} ->
            {:user, Users.get_user_by_username(username)}

          %CreateUser{username: username} ->
            {:user, Users.register(username)}

          %GetCampaigns{user_id: _user_id} ->
            {:campaigns, %{campaigns: Campaigns.get_campaigns() |> Enum.map(&%{levels: &1})}}

          %GetCampaign{user_id: _user_id, campaign_number: campaign_number} ->
            {:campaign, %{levels: Campaigns.get_campaign(campaign_number)}}

          %GetLevel{user_id: _user_id, level_id: level_id} ->
            {:level, Campaigns.get_level(level_id)}

          %FightLevel{user_id: user_id, level_id: level_id} ->
            {:battle_result, %{result: Battle.fight_level(user_id, level_id) |> Atom.to_string()}}

          %SelectUnit{user_id: user_id, unit_id: unit_id, slot: slot} ->
            {:unit, Units.select_unit(user_id, unit_id, slot)}

          %UnselectUnit{user_id: user_id, unit_id: unit_id} ->
            {:unit, Units.unselect_unit(user_id, unit_id)}

          %EquipItem{user_id: user_id, item_id: item_id, unit_id: unit_id} ->
            {:item, Items.equip_item(user_id, item_id, unit_id)}

          %UnequipItem{user_id: user_id, item_id: item_id} ->
            {:item, Items.unequip_item(user_id, item_id)}

          %GetItem{user_id: _user_id, item_id: item_id} ->
            {:item, Items.get_item(item_id)}

          %LevelUpItem{user_id: user_id, item_id: item_id} ->
            {:ok, item} = Items.level_up(user_id, item_id)
            {:item, item}

          unknown_request ->
            Logger.error(
              "[Gateway.ChampionsSocketHandler] Received unknown request #{unknown_request}"
            )
        end

      encode =
        WebSocketResponse.encode(%WebSocketResponse{response_type: response})

      {:reply, {:binary, encode}, state}
    else
      unknown_request ->
        Logger.error(
          "[Gateway.ChampionsSocketHandler] Received unknown request #{unknown_request}"
        )

        {:ok, state}
    end
  end

  @impl true
  def websocket_handle(message, state) do
    Logger.info("You should not be here: #{inspect(message)}")
    {:reply, {:text, "error"}, state}
  end

  @impl true
  def websocket_info(message, state) do
    Logger.info("You should not be here: #{inspect(message)}")
    {:reply, {:binary, Jason.encode!(%{})}, state}
  end
end
