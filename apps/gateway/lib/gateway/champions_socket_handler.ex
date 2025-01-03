defmodule Gateway.ChampionsSocketHandler do
  @moduledoc """
  Module that handles cowboy websocket requests
  """

  require Logger

  alias Gateway.Serialization.PurchaseDungeonUpgrade
  alias Gateway.Serialization.LevelUpDungeonSettlement
  alias Gateway.Serialization.ClaimDungeonAfkRewards
  alias Gateway.Serialization.FuseItems

  alias Gateway.Serialization.{
    StatAffected,
    Death,
    TagReceived,
    TagExpired,
    ModifierExpired,
    ModifierReceived,
    SkillAction,
    WebSocketResponse,
    ExecutionReceived,
    EnergyRegen,
    StatOverride
  }

  alias Champions.{Battle, Campaigns, Gacha, Items, Users, Units}

  alias Gateway.Serialization.{
    WebSocketRequest,
    GetUser,
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
    GetBoxes,
    GetBox,
    Summon,
    GetUserSuperCampaignProgresses,
    LevelUpKalineTree,
    ClaimDungeonAfkRewards,
    LevelUpDungeonSettlement
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
    case WebSocketRequest.decode(message) do
      %WebSocketRequest{request_type: {_type, request}} ->
        response = handle(request)
        encode = WebSocketResponse.encode(%WebSocketResponse{response_type: response})
        {:reply, {:binary, encode}, state}

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

  defp handle(%CreateUser{username: username}),
    do: Users.register(username) |> prepare_response(:user)

  defp handle(%GetCampaigns{user_id: _user_id}) do
    case Campaigns.get_campaigns() do
      {:error, reason} ->
        prepare_response({:error, reason}, nil)

      {:ok, campaigns} ->
        prepare_response(%{campaigns: Enum.map(campaigns, &prepare_campaign/1)}, :campaigns)
    end
  end

  defp handle(%GetCampaign{user_id: _user_id, campaign_id: campaign_id}) do
    case Campaigns.get_campaign(campaign_id) do
      {:error, reason} ->
        prepare_response({:error, reason}, nil)

      {:ok, campaign} ->
        campaign
        |> prepare_campaign()
        |> prepare_response(:campaign)
    end
  end

  defp handle(%GetLevel{user_id: _user_id, level_id: level_id}),
    do: Campaigns.get_level(level_id) |> prepare_response(:level)

  defp handle(%FightLevel{user_id: user_id, level_id: level_id}) do
    case Battle.fight_level(user_id, level_id) do
      {:error, reason} ->
        prepare_response({:error, reason}, nil)

      {:ok, battle_result} ->
        battle_result
        |> update_in([:steps], fn steps ->
          Enum.map(steps, &prepare_step/1)
        end)
        |> prepare_response(:battle_result)
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

  defp handle(%FuseUnit{
         user_id: user_id,
         unit_id: unit_id,
         consumed_units_ids: consumed_units_ids
       }) do
    case Units.fuse(user_id, unit_id, consumed_units_ids) do
      {:ok, result} -> prepare_response(result, :unit)
      {:error, reason} -> prepare_response({:error, reason}, nil)
    end
  end

  defp handle(%EquipItem{user_id: user_id, item_id: item_id, unit_id: unit_id}),
    do: Items.equip_item(user_id, item_id, unit_id) |> prepare_response(:item)

  defp handle(%UnequipItem{user_id: user_id, item_id: item_id}),
    do: Items.unequip_item(user_id, item_id) |> prepare_response(:item)

  defp handle(%GetItem{user_id: _user_id, item_id: item_id}),
    do: Items.get_item(item_id) |> prepare_response(:item)

  defp handle(%FuseItems{user_id: user_id, item_ids: item_ids}) do
    case Items.fuse(user_id, item_ids) do
      {:ok, item} -> prepare_response(item, :item)
      {:error, reason} -> prepare_response({:error, reason}, nil)
    end
  end

  defp handle(%GetKalineAfkRewards{user_id: user_id}),
    do: prepare_response(%{afk_rewards: Users.get_afk_rewards(user_id, :kaline)}, :afk_rewards)

  defp handle(%ClaimKalineAfkRewards{user_id: user_id}),
    do: Users.claim_afk_rewards(user_id, :kaline) |> prepare_response(:user)

  defp handle(%GetBoxes{}) do
    %{boxes: Gacha.get_boxes()} |> prepare_response(:boxes)
  end

  defp handle(%GetBox{box_id: box_id}) do
    case Gacha.get_box(box_id) do
      {:ok, box} -> prepare_response(box, :box)
      {:error, reason} -> prepare_response({:error, reason}, nil)
    end
  end

  defp handle(%Summon{user_id: user_id, box_id: box_id}) do
    case Gacha.summon(user_id, box_id) do
      {:ok, user_and_unit} -> prepare_response(user_and_unit, :user_and_unit)
      {:error, reason} -> prepare_response({:error, reason}, nil)
    end
  end

  defp handle(%GetUserSuperCampaignProgresses{user_id: user_id}) do
    super_campaign_progresses =
      Campaigns.get_user_super_campaign_progresses(user_id)
      |> Enum.map(fn super_campaign_progress ->
        %{
          level_id: super_campaign_progress.level_id,
          user_id: super_campaign_progress.user_id,
          campaign_id: super_campaign_progress.level.campaign_id,
          super_campaign_name: super_campaign_progress.super_campaign.name
        }
      end)

    prepare_response(%{super_campaign_progresses: super_campaign_progresses}, :super_campaign_progresses)
  end

  defp handle(%LevelUpKalineTree{user_id: user_id}) do
    case Users.level_up_kaline_tree(user_id) do
      {:ok, result} -> prepare_response(result, :user)
      {:error, reason} -> prepare_response({:error, reason}, nil)
    end
  end

  defp handle(%ClaimDungeonAfkRewards{user_id: user_id}) do
    Users.claim_afk_rewards(user_id, :dungeon) |> prepare_response(:user)
  end

  defp handle(%LevelUpDungeonSettlement{user_id: user_id}) do
    case Users.level_up_dungeon_settlement(user_id) do
      {:ok, result} -> prepare_response(result, :user)
      {:error, reason} -> prepare_response({:error, reason}, nil)
    end
  end

  defp handle(%PurchaseDungeonUpgrade{user_id: user_id, upgrade_id: upgrade_id}) do
    case Users.purchase_dungeon_upgrade(user_id, upgrade_id) do
      {:ok, result} -> prepare_response(result, :user)
      {:error, reason} -> prepare_response({:error, reason}, nil)
    end
  end

  defp handle(unknown_request),
    do: Logger.warning("[Gateway.ChampionsSocketHandler] Received unknown request #{unknown_request}")

  defp prepare_campaign(campaign) do
    %{
      id: campaign.id,
      super_campaign_name: campaign.super_campaign.name,
      campaign_number: campaign.campaign_number,
      levels: campaign.levels
    }
  end

  defp prepare_step(step) do
    update_in(step, [:actions], fn actions ->
      Enum.map(actions, &prepare_action/1)
    end)
  end

  defp prepare_action(%{action_type: {:skill_action, action}}) do
    %{
      action_type:
        {:skill_action,
         Kernel.struct(
           SkillAction,
           action
         )}
    }
  end

  defp prepare_action(%{action_type: {:modifier_received, action}}) do
    %{
      action_type:
        {:modifier_received,
         Kernel.struct(
           ModifierReceived,
           update_in(action, [:stat_affected], &Kernel.struct(StatAffected, &1))
         )}
    }
  end

  defp prepare_action(%{action_type: {:tag_received, action}}) do
    %{
      action_type:
        {:tag_received,
         Kernel.struct(
           TagReceived,
           action
         )}
    }
  end

  defp prepare_action(%{action_type: {:tag_expired, action}}) do
    %{
      action_type:
        {:tag_expired,
         Kernel.struct(
           TagExpired,
           action
         )}
    }
  end

  defp prepare_action(%{action_type: {:modifier_expired, action}}) do
    %{
      action_type:
        {:modifier_expired,
         Kernel.struct(
           ModifierExpired,
           update_in(action, [:stat_affected], &Kernel.struct(StatAffected, &1))
         )}
    }
  end

  defp prepare_action(%{action_type: {:death, action}}) do
    %{
      action_type:
        {:death,
         Kernel.struct(
           Death,
           action
         )}
    }
  end

  defp prepare_action(%{action_type: {:execution_received, action}}) do
    %{
      action_type:
        {:execution_received,
         Kernel.struct(
           ExecutionReceived,
           update_in(action, [:stat_affected], &Kernel.struct(StatAffected, &1))
         )}
    }
  end

  defp prepare_action(%{action_type: {:energy_regen, action}}) do
    %{
      action_type:
        {:energy_regen,
         Kernel.struct(
           EnergyRegen,
           action
         )}
    }
  end

  defp prepare_action(%{action_type: {:stat_override, action}}) do
    %{
      action_type:
        {:stat_override,
         Kernel.struct(
           StatOverride,
           update_in(action, [:stat_affected], &Kernel.struct(StatAffected, &1))
         )}
    }
  end

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
