defmodule Gateway.SocketTester do
  @moduledoc """
  Module for manually testing the CoM websocket.
  Logs received messages and keeps the last one received in the state.

  Example usage:
      {_ok, pid} = SocketTester.start_link()
      SocketTester.create_user(pid, "Username")
      SocketTester.get_user_by_username(pid, "Username")

  To use SocketTester in the elixir shell, you can move this file under the `lib/gateway/` directory.
  To fetch the last message received by the SocketTester, you can run:

  ```
  send(pid, {:last_message, self()})
  ```

  This will send the last message received by the SocketTester to the caller process (our shell).
  You can then use `flush()` to see the message.
  """

  @ws_url "ws://127.0.0.1:4001/2"

  use WebSockex

  require Logger
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
    LevelUpUnit,
    TierUpUnit,
    FuseUnit,
    EquipItem,
    UnequipItem,
    GetItem,
    FuseItems,
    GetKalineAfkRewards,
    ClaimKalineAfkRewards,
    GetBox,
    GetBoxes,
    Summon,
    GetUserSuperCampaignProgresses,
    LevelUpKalineTree,
    ClaimDungeonAfkRewards,
    LevelUpDungeonSettlement,
    PurchaseDungeonUpgrade
  }

  def start_link() do
    WebSockex.start_link(@ws_url, __MODULE__, nil)
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

  def get_campaign(pid, user_id, campaign_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:get_campaign, %GetCampaign{user_id: user_id, campaign_id: campaign_id}}
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
           request_type: {:select_unit, %SelectUnit{user_id: user_id, unit_id: unit_id, slot: slot}}
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

  def level_up_unit(pid, user_id, unit_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:level_up_unit, %LevelUpUnit{user_id: user_id, unit_id: unit_id}}
         })}
      )

  def tier_up_unit(pid, user_id, unit_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:tier_up_unit, %TierUpUnit{user_id: user_id, unit_id: unit_id}}
         })}
      )

  def fuse_unit(pid, user_id, unit_id, consumed_units_ids),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type:
             {:fuse_unit,
              %FuseUnit{
                user_id: user_id,
                unit_id: unit_id,
                consumed_units_ids: consumed_units_ids
              }}
         })}
      )

  def equip_item(pid, user_id, item_id, unit_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:equip_item, %EquipItem{user_id: user_id, item_id: item_id, unit_id: unit_id}}
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

  def fuse_items(pid, user_id, item_ids),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:fuse_items, %FuseItems{user_id: user_id, item_ids: item_ids}}
         })}
      )

  def get_boxes(pid, user_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:get_boxes, %GetBoxes{user_id: user_id}}
         })}
      )

  def get_box(pid, box_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:get_box, %GetBox{box_id: box_id}}
         })}
      )

  def summon(pid, user_id, box_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:summon, %Summon{user_id: user_id, box_id: box_id}}
         })}
      )

  def get_kaline_afk_rewards(pid, user_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:get_kaline_afk_rewards, %GetKalineAfkRewards{user_id: user_id}}
         })}
      )

  def claim_kaline_afk_rewards(pid, user_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:claim_kaline_afk_rewards, %ClaimKalineAfkRewards{user_id: user_id}}
         })}
      )

  def get_user_super_campaign_progresses(pid, user_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:get_user_super_campaign_progresses, %GetUserSuperCampaignProgresses{user_id: user_id}}
         })}
      )

  def level_up_kaline_tree(pid, user_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:level_up_kaline_tree, %LevelUpKalineTree{user_id: user_id}}
         })}
      )

  def claim_dungeon_afk_rewards(pid, user_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:claim_dungeon_afk_rewards, %ClaimDungeonAfkRewards{user_id: user_id}}
         })}
      )

  def level_up_dungeon_settlement(pid, user_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:level_up_dungeon_settlement, %LevelUpDungeonSettlement{user_id: user_id}}
         })}
      )

  def purchase_dungeon_upgrade(pid, user_id, upgrade_id),
    do:
      WebSockex.send_frame(
        pid,
        {:binary,
         WebSocketRequest.encode(%WebSocketRequest{
           request_type: {:purchase_dungeon_upgrade, %PurchaseDungeonUpgrade{user_id: user_id, upgrade_id: upgrade_id}}
         })}
      )

  def handle_frame({:binary, message}, _state) do
    message = WebSocketResponse.decode(message)
    message |> inspect(pretty: true) |> Logger.info()

    {:ok, message}
  end

  def handle_info({:last_message, pid}, state) do
    send(pid, state)
    {:ok, state}
  end
end
