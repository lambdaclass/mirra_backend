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
    LevelUpUnit,
    TierUpUnit,
    EquipItem,
    UnequipItem,
    GetItem,
    LevelUpItem
  }

  @behaviour :cowboy_websocket

  @impl true
  def init(req, _opts) do
    {:cowboy_websocket, req, %{}}
  end

  @impl true
  def websocket_init(state) do
    Logger.info("Websocket INIT called")

    {:reply, {:pong, ""}, state}
  end

  def websocket_handle({:binary, message}, state) do
    with %WebSocketRequest{request_type: {_type, request}} <- WebSocketRequest.decode(message) do
      response = handle(request)

      encode = WebSocketResponse.encode(%WebSocketResponse{response_type: response})

      {:reply, {:binary, encode}, state}
    else
      unknown_request ->
        Logger.warning("[Gateway.ChampionsSocketHandler] Received unknown request #{unknown_request}")

        {:ok, state}
    end
  end

  @impl true
  def websocket_handle(:ping, state) do
    {:reply, :pong, state}
  end

  @impl true
  def websocket_handle(message, state) do
    Logger.info("[Handler.websocket_handle] You should not be here: #{inspect(message)}")
    {:reply, {:text, "error"}, state}
  end

  defp handle(%GetUser{user_id: user_id}), do: Users.get_user(user_id) |> prepare_response(:user)

  defp handle(%GetUserByUsername{username: username}),
    do: Users.get_user_by_username(username) |> prepare_response(:user)

  defp handle(%CreateUser{username: username}),
    do: Users.register(username) |> prepare_response(:user)

  defp handle(%GetCampaigns{user_id: _user_id}) do
    case Campaigns.get_campaigns() do
      {:error, reason} ->
        prepare_response({:error, reason}, nil)

      campaigns ->
        prepare_response(%{campaigns: campaigns}, :campaigns)
    end
  end

  defp handle(%GetCampaign{user_id: _user_id, campaign_id: campaign_id}) do
    case Campaigns.get_campaign(campaign_id) do
      {:error, reason} ->
        prepare_response({:error, reason}, nil)

      {:ok, campaign} ->
        prepare_response(%{levels: campaign}, :campaign)
    end
  end

  defp handle(%GetLevel{user_id: _user_id, level_id: level_id}),
    do: Campaigns.get_level(level_id) |> prepare_response(:level)

  defp handle(%FightLevel{user_id: user_id, level_id: level_id}) do
    case Battle.fight_level(user_id, level_id) do
      {:error, reason} -> prepare_response({:error, reason}, nil)
      battle_result -> prepare_response(%{result: Atom.to_string(battle_result)}, :battle_result)
    end
  end

  defp handle(%SelectUnit{user_id: user_id, unit_id: unit_id, slot: slot}),
    do: Units.select_unit(user_id, unit_id, slot) |> prepare_response(:unit)

  defp handle(%UnselectUnit{user_id: user_id, unit_id: unit_id}),
    do: Units.unselect_unit(user_id, unit_id) |> prepare_response(:unit)

  defp handle(%LevelUpUnit{user_id: user_id, unit_id: unit_id}) do
    case Units.level_up(user_id, unit_id) do
      {:ok, result} -> prepare_response(result, :unit_and_currencies)
      {:error, reason} -> prepare_response({:error, reason}, nil)
    end
  end

  defp handle(%TierUpUnit{user_id: user_id, unit_id: unit_id}) do
    case Units.tier_up(user_id, unit_id) do
      {:ok, result} -> prepare_response(result, :unit_and_currencies)
      {:error, reason} -> prepare_response({:error, reason}, nil)
    end
  end

  defp handle(%EquipItem{user_id: user_id, item_id: item_id, unit_id: unit_id}),
    do: Items.equip_item(user_id, item_id, unit_id) |> prepare_response(:item)

  defp handle(%UnequipItem{user_id: user_id, item_id: item_id}),
    do: Items.unequip_item(user_id, item_id) |> prepare_response(:item)

  defp handle(%GetItem{user_id: _user_id, item_id: item_id}),
    do: Items.get_item(item_id) |> prepare_response(:item)

  defp handle(%LevelUpItem{user_id: user_id, item_id: item_id}) do
    case Items.level_up(user_id, item_id) do
      {:ok, %{item: item}} -> prepare_response(item, :item)
      {:error, reason} -> prepare_response({:error, reason}, nil)
      {:error, _, _, _} -> prepare_response({:error, :transaction}, nil)
    end
  end

  defp handle(unknown_request),
    do: Logger.warning("[Gateway.ChampionsSocketHandler] Received unknown request #{unknown_request}")

  defp prepare_response({:error, reason}, _response_type) when is_atom(reason),
    do: prepare_response({:error, Atom.to_string(reason)}, nil)

  defp prepare_response({:error, reason}, _response_type), do: {:error, %{reason: reason}}
  defp prepare_response({:ok, result}, response_type), do: {response_type, result}
  defp prepare_response(result, response_type), do: {response_type, result}

  @impl true
  def websocket_info(message, state) do
    Logger.info("[Handler.websocket_info] You should not be here: #{inspect(message)}")
    {:reply, {:binary, Jason.encode!(%{})}, state}
  end
end
