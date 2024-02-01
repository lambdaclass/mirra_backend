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
            prepare_response(Users.get_user(user_id), :user)

          %GetUserByUsername{username: username} ->
            prepare_response(Users.get_user_by_username(username), :user)

          %CreateUser{username: username} ->
            prepare_response(Users.register(username), :user)

          %GetCampaigns{user_id: _user_id} ->
            case Campaigns.get_campaigns() do
              {:error, reason} -> {:error, reason}
              campaigns -> {:campaigns, %{campaigns: Enum.map(campaigns, &%{levels: &1})}}
            end

          %GetCampaign{user_id: _user_id, campaign_number: campaign_number} ->
            prepare_response(Campaigns.get_campaign(campaign_number), :campaign)

          %GetLevel{user_id: _user_id, level_id: level_id} ->
            prepare_response(Campaigns.get_level(level_id), :level)

          %FightLevel{user_id: user_id, level_id: level_id} ->
            case Battle.fight_level(user_id, level_id) do
              {:error, reason} -> {:error, reason}
              battle_result -> {:battle_result, Atom.to_string(battle_result)}
            end

          %SelectUnit{user_id: user_id, unit_id: unit_id, slot: slot} ->
            prepare_response(Units.select_unit(user_id, unit_id, slot), :unit)

          %UnselectUnit{user_id: user_id, unit_id: unit_id} ->
            prepare_response(Units.unselect_unit(user_id, unit_id), :unit)

          %EquipItem{user_id: user_id, item_id: item_id, unit_id: unit_id} ->
            prepare_response(Items.equip_item(user_id, item_id, unit_id), :item)

          %UnequipItem{user_id: user_id, item_id: item_id} ->
            prepare_response(Items.unequip_item(user_id, item_id), :item)

          %GetItem{user_id: _user_id, item_id: item_id} ->
            prepare_response(Items.get_item(item_id), :item)

          %LevelUpItem{user_id: user_id, item_id: item_id} ->
            prepare_response(Items.level_up(user_id, item_id), :item)

          unknown_request ->
            Logger.warning(
              "[Gateway.ChampionsSocketHandler] Received unknown request #{unknown_request}"
            )
        end

      encode =
        WebSocketResponse.encode(%WebSocketResponse{response_type: response})

      {:reply, {:binary, encode}, state}
    else
      unknown_request ->
        Logger.warning(
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

  defp prepare_response({:error, reason}, response_type) when is_atom(reason),
    do: prepare_response({:error, Atom.to_string(reason)}, response_type)

  defp prepare_response({:error, reason}, _response_type), do: {:error, %{reason: reason}}
  defp prepare_response({:ok, result}, response_type), do: {response_type, result}
  defp prepare_response(result, response_type), do: {response_type, result}

  @impl true
  def websocket_info(message, state) do
    Logger.info("You should not be here: #{inspect(message)}")
    {:reply, {:binary, Jason.encode!(%{})}, state}
  end
end
