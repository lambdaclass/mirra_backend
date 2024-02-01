defmodule SocketTester do
  @moduledoc """
  Module for manually testing the CoM websocket.

  Example usage:
      {_ok, pid} = SocketTester.start_link "123"
      SocketTester.create_user(pid, "Username")
      SocketTester.get_user_by_username(pid, "Username")
  """

  @ws_url "ws://127.0.0.1:4001/2/123"

  use WebSockex

  alias Gateway.Serialization.WebSocketResponse

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

  def start_link() do
    WebSockex.start_link(@ws_url, __MODULE__, %{})
  end

  def get_user(pid, user_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:get_user, %GetUser{user_id: user_id}}
         })}
      )

  def get_user_by_username(pid, username),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:get_user_by_username, %GetUserByUsername{username: username}}
         })}
      )

  def create_user(pid, username),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:create_user, %CreateUser{username: username}}
         })}
      )

  def get_campaigns(pid, user_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:get_campaigns, %GetCampaigns{user_id: user_id}}
         })}
      )

  def get_campaign(pid, user_id, campaign_number),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type:
             {:get_campaign, %GetCampaign{user_id: user_id, campaign_number: campaign_number}}
         })}
      )

  def get_level(pid, user_id, level_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:get_level, %GetLevel{user_id: user_id, level_id: level_id}}
         })}
      )

  def fight_level(pid, user_id, level_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:fight_level, %FightLevel{user_id: user_id, level_id: level_id}}
         })}
      )

  def select_unit(pid, user_id, unit_id, slot),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type:
             {:select_unit, %SelectUnit{user_id: user_id, unit_id: unit_id, slot: slot}}
         })}
      )

  def unselect_unit(pid, user_id, unit_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:unselect_unit, %UnselectUnit{user_id: user_id, unit_id: unit_id}}
         })}
      )

  def equip_item(pid, user_id, item_id, unit_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type:
             {:equip_item, %EquipItem{user_id: user_id, item_id: item_id, unit_id: unit_id}}
         })}
      )

  def unequip_item(pid, user_id, item_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:unequip_item, %UnequipItem{user_id: user_id, item_id: item_id}}
         })}
      )

  def get_item(pid, user_id, item_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:get_item, %GetItem{user_id: user_id, item_id: item_id}}
         })}
      )

  def level_up_item(pid, user_id, item_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:level_up_item, %LevelUpItem{user_id: user_id, item_id: item_id}}
         })}
      )

  def handle_frame({:binary, message}, state) do
    WebSocketResponse.decode(message) |> IO.inspect(label: :Response)
    {:ok, state}
  end
end
