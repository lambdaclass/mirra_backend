defmodule Gateway.Serialization.SkillActionType do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:ANIMATION_START, 0)
  field(:EFFECT_TRIGGER, 1)
  field(:EFFECT_HIT, 2)
  field(:EFFECT_MISS, 3)
end

defmodule Gateway.Serialization.Stat do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:HEALTH, 0)
  field(:ENERGY, 1)
  field(:ATTACK, 2)
  field(:DEFENSE, 3)
  field(:DAMAGE_REDUCTION, 4)
  field(:SPEED, 5)
end

defmodule Gateway.Serialization.WebSocketRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  oneof(:request_type, 0)

  field(:get_user, 1, type: Gateway.Serialization.GetUser, json_name: "getUser", oneof: 0)
  field(:create_user, 3, type: Gateway.Serialization.CreateUser, json_name: "createUser", oneof: 0)

  field(:get_campaigns, 4,
    type: Gateway.Serialization.GetCampaigns,
    json_name: "getCampaigns",
    oneof: 0
  )

  field(:get_campaign, 5,
    type: Gateway.Serialization.GetCampaign,
    json_name: "getCampaign",
    oneof: 0
  )

  field(:get_level, 6, type: Gateway.Serialization.GetLevel, json_name: "getLevel", oneof: 0)
  field(:fight_level, 7, type: Gateway.Serialization.FightLevel, json_name: "fightLevel", oneof: 0)
  field(:select_unit, 9, type: Gateway.Serialization.SelectUnit, json_name: "selectUnit", oneof: 0)

  field(:unselect_unit, 10,
    type: Gateway.Serialization.UnselectUnit,
    json_name: "unselectUnit",
    oneof: 0
  )

  field(:level_up_unit, 11,
    type: Gateway.Serialization.LevelUpUnit,
    json_name: "levelUpUnit",
    oneof: 0
  )

  field(:tier_up_unit, 12,
    type: Gateway.Serialization.TierUpUnit,
    json_name: "tierUpUnit",
    oneof: 0
  )

  field(:fuse_unit, 13, type: Gateway.Serialization.FuseUnit, json_name: "fuseUnit", oneof: 0)
  field(:equip_item, 14, type: Gateway.Serialization.EquipItem, json_name: "equipItem", oneof: 0)

  field(:unequip_item, 15,
    type: Gateway.Serialization.UnequipItem,
    json_name: "unequipItem",
    oneof: 0
  )

  field(:get_item, 16, type: Gateway.Serialization.GetItem, json_name: "getItem", oneof: 0)
  field(:fuse_items, 17, type: Gateway.Serialization.FuseItems, json_name: "fuseItems", oneof: 0)
  field(:get_boxes, 18, type: Gateway.Serialization.GetBoxes, json_name: "getBoxes", oneof: 0)
  field(:get_box, 19, type: Gateway.Serialization.GetBox, json_name: "getBox", oneof: 0)
  field(:summon, 20, type: Gateway.Serialization.Summon, oneof: 0)

  field(:get_kaline_afk_rewards, 21,
    type: Gateway.Serialization.GetKalineAfkRewards,
    json_name: "getKalineAfkRewards",
    oneof: 0
  )

  field(:claim_kaline_afk_rewards, 22,
    type: Gateway.Serialization.ClaimKalineAfkRewards,
    json_name: "claimKalineAfkRewards",
    oneof: 0
  )

  field(:get_user_super_campaign_progresses, 23,
    type: Gateway.Serialization.GetUserSuperCampaignProgresses,
    json_name: "getUserSuperCampaignProgresses",
    oneof: 0
  )

  field(:level_up_kaline_tree, 24,
    type: Gateway.Serialization.LevelUpKalineTree,
    json_name: "levelUpKalineTree",
    oneof: 0
  )

  field(:claim_dungeon_afk_rewards, 25,
    type: Gateway.Serialization.ClaimDungeonAfkRewards,
    json_name: "claimDungeonAfkRewards",
    oneof: 0
  )

  field(:level_up_dungeon_settlement, 26,
    type: Gateway.Serialization.LevelUpDungeonSettlement,
    json_name: "levelUpDungeonSettlement",
    oneof: 0
  )

  field(:purchase_dungeon_upgrade, 27,
    type: Gateway.Serialization.PurchaseDungeonUpgrade,
    json_name: "purchaseDungeonUpgrade",
    oneof: 0
  )
end

defmodule Gateway.Serialization.GetUser do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
end

defmodule Gateway.Serialization.GetUserByUsername do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:username, 1, type: :string)
end

defmodule Gateway.Serialization.CreateUser do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:username, 1, type: :string)
end

defmodule Gateway.Serialization.GetCampaigns do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
end

defmodule Gateway.Serialization.GetCampaign do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:campaign_id, 2, type: :string, json_name: "campaignId")
end

defmodule Gateway.Serialization.GetLevel do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:level_id, 2, type: :string, json_name: "levelId")
end

defmodule Gateway.Serialization.FightLevel do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:level_id, 2, type: :string, json_name: "levelId")
end

defmodule Gateway.Serialization.SelectUnit do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:unit_id, 2, type: :string, json_name: "unitId")
  field(:slot, 3, type: :uint32)
end

defmodule Gateway.Serialization.UnselectUnit do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:unit_id, 2, type: :string, json_name: "unitId")
end

defmodule Gateway.Serialization.LevelUpUnit do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:unit_id, 2, type: :string, json_name: "unitId")
end

defmodule Gateway.Serialization.TierUpUnit do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:unit_id, 2, type: :string, json_name: "unitId")
end

defmodule Gateway.Serialization.FuseUnit do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:unit_id, 2, type: :string, json_name: "unitId")
  field(:consumed_units_ids, 3, repeated: true, type: :string, json_name: "consumedUnitsIds")
end

defmodule Gateway.Serialization.EquipItem do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:item_id, 2, type: :string, json_name: "itemId")
  field(:unit_id, 3, type: :string, json_name: "unitId")
end

defmodule Gateway.Serialization.UnequipItem do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:item_id, 2, type: :string, json_name: "itemId")
end

defmodule Gateway.Serialization.GetItem do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:item_id, 2, type: :string, json_name: "itemId")
end

defmodule Gateway.Serialization.FuseItems do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:item_ids, 2, repeated: true, type: :string, json_name: "itemIds")
end

defmodule Gateway.Serialization.GetKalineAfkRewards do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
end

defmodule Gateway.Serialization.ClaimKalineAfkRewards do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
end

defmodule Gateway.Serialization.GetBoxes do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
end

defmodule Gateway.Serialization.GetBox do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:box_id, 1, type: :string, json_name: "boxId")
end

defmodule Gateway.Serialization.Summon do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:box_id, 2, type: :string, json_name: "boxId")
end

defmodule Gateway.Serialization.GetUserSuperCampaignProgresses do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
end

defmodule Gateway.Serialization.LevelUpKalineTree do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
end

defmodule Gateway.Serialization.ClaimDungeonAfkRewards do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
end

defmodule Gateway.Serialization.LevelUpDungeonSettlement do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
end

defmodule Gateway.Serialization.PurchaseDungeonUpgrade do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:upgrade_id, 2, type: :string, json_name: "upgradeId")
end

defmodule Gateway.Serialization.WebSocketResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  oneof(:response_type, 0)

  field(:user, 1, type: Gateway.Serialization.User, oneof: 0)
  field(:unit, 2, type: Gateway.Serialization.Unit, oneof: 0)
  field(:units, 3, type: Gateway.Serialization.Units, oneof: 0)

  field(:unit_and_currencies, 4,
    type: Gateway.Serialization.UnitAndCurrencies,
    json_name: "unitAndCurrencies",
    oneof: 0
  )

  field(:item, 5, type: Gateway.Serialization.Item, oneof: 0)
  field(:campaigns, 6, type: Gateway.Serialization.Campaigns, oneof: 0)
  field(:campaign, 7, type: Gateway.Serialization.Campaign, oneof: 0)
  field(:level, 8, type: Gateway.Serialization.Level, oneof: 0)

  field(:battle_result, 9,
    type: Gateway.Serialization.BattleResult,
    json_name: "battleResult",
    oneof: 0
  )

  field(:error, 10, type: Gateway.Serialization.Error, oneof: 0)
  field(:boxes, 11, type: Gateway.Serialization.Boxes, oneof: 0)
  field(:box, 12, type: Gateway.Serialization.Box, oneof: 0)

  field(:user_and_unit, 13,
    type: Gateway.Serialization.UserAndUnit,
    json_name: "userAndUnit",
    oneof: 0
  )

  field(:afk_rewards, 14,
    type: Gateway.Serialization.AfkRewards,
    json_name: "afkRewards",
    oneof: 0
  )

  field(:super_campaign_progresses, 15,
    type: Gateway.Serialization.SuperCampaignProgresses,
    json_name: "superCampaignProgresses",
    oneof: 0
  )
end

defmodule Gateway.Serialization.User do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:id, 1, type: :string)
  field(:username, 2, type: :string)
  field(:level, 3, type: :uint64)
  field(:experience, 4, type: :uint64)
  field(:currencies, 7, repeated: true, type: Gateway.Serialization.UserCurrency)
  field(:units, 8, repeated: true, type: Gateway.Serialization.Unit)
  field(:items, 9, repeated: true, type: Gateway.Serialization.Item)

  field(:kaline_tree_level, 10,
    type: Gateway.Serialization.KalineTreeLevel,
    json_name: "kalineTreeLevel"
  )

  field(:dungeon_settlement_level, 11,
    type: Gateway.Serialization.DungeonSettlementLevel,
    json_name: "dungeonSettlementLevel"
  )

  field(:unlocks, 12, repeated: true, type: Gateway.Serialization.Unlock)
end

defmodule Gateway.Serialization.KalineTreeLevel do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:id, 1, type: :string)
  field(:level, 2, type: :uint64)
  field(:fertilizer_level_up_cost, 3, type: :uint64, json_name: "fertilizerLevelUpCost")
  field(:gold_level_up_cost, 4, type: :uint64, json_name: "goldLevelUpCost")
  field(:unlock_features, 5, repeated: true, type: :string, json_name: "unlockFeatures")

  field(:afk_reward_rates, 6,
    repeated: true,
    type: Gateway.Serialization.AfkRewardRate,
    json_name: "afkRewardRates"
  )
end

defmodule Gateway.Serialization.DungeonSettlementLevel do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:id, 1, type: :string)
  field(:level, 2, type: :uint64)

  field(:level_up_costs, 3,
    repeated: true,
    type: Gateway.Serialization.CurrencyCost,
    json_name: "levelUpCosts"
  )

  field(:max_dungeon, 4, type: :uint64, json_name: "maxDungeon")
  field(:max_factional, 5, type: :uint64, json_name: "maxFactional")
  field(:supply_cap, 6, type: :uint64, json_name: "supplyCap")

  field(:afk_reward_rates, 7,
    repeated: true,
    type: Gateway.Serialization.AfkRewardRate,
    json_name: "afkRewardRates"
  )
end

defmodule Gateway.Serialization.SuperCampaignProgresses do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:super_campaign_progresses, 1,
    repeated: true,
    type: Gateway.Serialization.SuperCampaignProgress,
    json_name: "superCampaignProgresses"
  )
end

defmodule Gateway.Serialization.SuperCampaignProgress do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:campaign_id, 2, type: :string, json_name: "campaignId")
  field(:level_id, 3, type: :string, json_name: "levelId")
  field(:super_campaign_name, 4, type: :string, json_name: "superCampaignName")
end

defmodule Gateway.Serialization.AfkRewardRate do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:kaline_tree_level_id, 1, type: :string, json_name: "kalineTreeLevelId")
  field(:currency, 2, type: Gateway.Serialization.Currency)
  field(:daily_rate, 3, type: :float, json_name: "dailyRate")
end

defmodule Gateway.Serialization.UserCurrency do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:currency, 1, type: Gateway.Serialization.Currency)
  field(:amount, 2, type: :uint32)
end

defmodule Gateway.Serialization.Currency do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:name, 1, type: :string)
end

defmodule Gateway.Serialization.Unit do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:id, 1, type: :string)
  field(:level, 2, type: :uint32)
  field(:tier, 3, type: :uint32)
  field(:rank, 4, type: :uint32)
  field(:selected, 5, type: :bool)
  field(:slot, 6, type: :uint32)
  field(:campaign_level_id, 7, type: :string, json_name: "campaignLevelId")
  field(:user_id, 8, type: :string, json_name: "userId")
  field(:character, 9, type: Gateway.Serialization.Character)
  field(:items, 10, repeated: true, type: Gateway.Serialization.Item)
end

defmodule Gateway.Serialization.Units do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:units, 1, repeated: true, type: Gateway.Serialization.Unit)
end

defmodule Gateway.Serialization.UnitAndCurrencies do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:unit, 1, type: Gateway.Serialization.Unit)

  field(:user_currency, 2,
    repeated: true,
    type: Gateway.Serialization.UserCurrency,
    json_name: "userCurrency"
  )
end

defmodule Gateway.Serialization.Character do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:active, 1, type: :bool)
  field(:name, 2, type: :string)
  field(:faction, 3, type: :string)
  field(:quality, 4, type: :uint32)
end

defmodule Gateway.Serialization.Item do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:id, 1, type: :string)
  field(:level, 2, type: :uint32)
  field(:template, 3, type: Gateway.Serialization.ItemTemplate)
  field(:user_id, 4, type: :string, json_name: "userId")
  field(:unit_id, 5, type: :string, json_name: "unitId")
end

defmodule Gateway.Serialization.ItemTemplate do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:id, 1, type: :string)
  field(:name, 2, type: :string)
  field(:type, 3, type: :string)
  field(:rarity, 4, type: :int32)
  field(:modifiers, 5, repeated: true, type: Gateway.Serialization.ItemModifier)
  field(:config_id, 6, type: :string, json_name: "configId")
  field(:upgrades_from_config_id, 7, type: :string, json_name: "upgradesFromConfigId")
  field(:upgrades_from_quantity, 8, type: :int32, json_name: "upgradesFromQuantity")

  field(:upgrade_costs, 9,
    repeated: true,
    type: Gateway.Serialization.CurrencyCost,
    json_name: "upgradeCosts"
  )
end

defmodule Gateway.Serialization.ItemModifier do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:attribute, 1, type: :string)
  field(:value, 2, type: :float)
  field(:operation, 3, type: :string)
end

defmodule Gateway.Serialization.Campaigns do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:campaigns, 1, repeated: true, type: Gateway.Serialization.Campaign)
end

defmodule Gateway.Serialization.Campaign do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:id, 1, type: :string)
  field(:super_campaign_name, 2, type: :string, json_name: "superCampaignName")
  field(:campaign_number, 3, type: :uint32, json_name: "campaignNumber")
  field(:levels, 4, repeated: true, type: Gateway.Serialization.Level)
end

defmodule Gateway.Serialization.Level do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:id, 1, type: :string)
  field(:campaign_id, 2, type: :string, json_name: "campaignId")
  field(:level_number, 3, type: :uint32, json_name: "levelNumber")
  field(:units, 4, repeated: true, type: Gateway.Serialization.Unit)

  field(:currency_rewards, 5,
    repeated: true,
    type: Gateway.Serialization.CurrencyReward,
    json_name: "currencyRewards"
  )

  field(:experience_reward, 6, type: :uint32, json_name: "experienceReward")

  field(:attempt_cost, 7,
    repeated: true,
    type: Gateway.Serialization.CurrencyCost,
    json_name: "attemptCost"
  )

  field(:max_units, 8, type: :uint32, json_name: "maxUnits")
end

defmodule Gateway.Serialization.CurrencyReward do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:currency, 1, type: Gateway.Serialization.Currency)
  field(:amount, 3, type: :uint64)
end

defmodule Gateway.Serialization.AfkRewards do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:afk_rewards, 1,
    repeated: true,
    type: Gateway.Serialization.AfkReward,
    json_name: "afkRewards"
  )
end

defmodule Gateway.Serialization.AfkReward do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:currency, 1, type: Gateway.Serialization.Currency)
  field(:amount, 2, type: :uint64)
end

defmodule Gateway.Serialization.Error do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:reason, 1, type: :string)
end

defmodule Gateway.Serialization.Boxes do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:boxes, 1, repeated: true, type: Gateway.Serialization.Box)
end

defmodule Gateway.Serialization.Box do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:id, 1, type: :string)
  field(:name, 2, type: :string)
  field(:description, 3, type: :string)
  field(:factions, 4, repeated: true, type: :string)

  field(:rank_weights, 5,
    repeated: true,
    type: Gateway.Serialization.RankWeights,
    json_name: "rankWeights"
  )

  field(:cost, 6, repeated: true, type: Gateway.Serialization.CurrencyCost)
end

defmodule Gateway.Serialization.RankWeights do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:rank, 1, type: :int32)
  field(:weight, 2, type: :int32)
end

defmodule Gateway.Serialization.CurrencyCost do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:currency, 1, type: Gateway.Serialization.Currency)
  field(:amount, 2, type: :int32)
end

defmodule Gateway.Serialization.UserAndUnit do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:user, 1, type: Gateway.Serialization.User)
  field(:unit, 2, type: Gateway.Serialization.Unit)
end

defmodule Gateway.Serialization.Unlock do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:name, 1, type: :string)
  field(:upgrade, 2, type: Gateway.Serialization.Upgrade)
end

defmodule Gateway.Serialization.Upgrade do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:name, 1, type: :string)
  field(:description, 2, type: :string)
  field(:group, 3, type: :int32)
  field(:cost, 4, repeated: true, type: Gateway.Serialization.CurrencyCost)
  field(:buffs, 5, repeated: true, type: Gateway.Serialization.Buff)
end

defmodule Gateway.Serialization.Buff do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:attribute, 1, type: :string)
  field(:value, 2, type: :float)
  field(:operation, 3, type: :string)
end

defmodule Gateway.Serialization.BattleResult do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:initial_state, 1, type: Gateway.Serialization.State, json_name: "initialState")
  field(:steps, 2, repeated: true, type: Gateway.Serialization.Step)
  field(:result, 3, type: :string)
end

defmodule Gateway.Serialization.State do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:units, 1, repeated: true, type: Gateway.Serialization.BattleUnit)
end

defmodule Gateway.Serialization.BattleUnit do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:id, 1, type: :string)
  field(:health, 2, type: :int32)
  field(:slot, 3, type: :int32)
  field(:character_id, 4, type: :string, json_name: "characterId")
  field(:team, 5, type: :int32)
end

defmodule Gateway.Serialization.Step do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:step_number, 1, type: :int32, json_name: "stepNumber")
  field(:actions, 2, repeated: true, type: Gateway.Serialization.Action)
end

defmodule Gateway.Serialization.Action do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  oneof(:action_type, 0)

  field(:skill_action, 1,
    type: Gateway.Serialization.SkillAction,
    json_name: "skillAction",
    oneof: 0
  )

  field(:modifier_received, 2,
    type: Gateway.Serialization.ModifierReceived,
    json_name: "modifierReceived",
    oneof: 0
  )

  field(:tag_received, 3,
    type: Gateway.Serialization.TagReceived,
    json_name: "tagReceived",
    oneof: 0
  )

  field(:modifier_expired, 4,
    type: Gateway.Serialization.ModifierExpired,
    json_name: "modifierExpired",
    oneof: 0
  )

  field(:tag_expired, 5, type: Gateway.Serialization.TagExpired, json_name: "tagExpired", oneof: 0)
  field(:death, 6, type: Gateway.Serialization.Death, oneof: 0)

  field(:execution_received, 7,
    type: Gateway.Serialization.ExecutionReceived,
    json_name: "executionReceived",
    oneof: 0
  )

  field(:energy_regen, 8,
    type: Gateway.Serialization.EnergyRegen,
    json_name: "energyRegen",
    oneof: 0
  )

  field(:stat_override, 9,
    type: Gateway.Serialization.StatOverride,
    json_name: "statOverride",
    oneof: 0
  )
end

defmodule Gateway.Serialization.StatAffected do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:stat, 1, type: Gateway.Serialization.Stat, enum: true)
  field(:amount, 2, type: :float)
end

defmodule Gateway.Serialization.SkillAction do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:caster_id, 1, type: :string, json_name: "casterId")
  field(:target_ids, 2, repeated: true, type: :string, json_name: "targetIds")
  field(:skill_id, 3, type: :string, json_name: "skillId")

  field(:skill_action_type, 4,
    type: Gateway.Serialization.SkillActionType,
    json_name: "skillActionType",
    enum: true
  )
end

defmodule Gateway.Serialization.ExecutionReceived do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:target_id, 1, type: :string, json_name: "targetId")
  field(:stat_affected, 2, type: Gateway.Serialization.StatAffected, json_name: "statAffected")
end

defmodule Gateway.Serialization.ModifierReceived do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:skill_id, 1, type: :string, json_name: "skillId")
  field(:target_id, 2, type: :string, json_name: "targetId")
  field(:stat_affected, 3, type: Gateway.Serialization.StatAffected, json_name: "statAffected")
  field(:operation, 4, type: :string)
end

defmodule Gateway.Serialization.TagReceived do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:skill_id, 1, type: :string, json_name: "skillId")
  field(:target_id, 2, type: :string, json_name: "targetId")
  field(:tag, 3, type: :string)
end

defmodule Gateway.Serialization.ModifierExpired do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:skill_id, 1, type: :string, json_name: "skillId")
  field(:target_id, 2, type: :string, json_name: "targetId")
  field(:stat_affected, 3, type: Gateway.Serialization.StatAffected, json_name: "statAffected")
  field(:operation, 4, type: :string)
end

defmodule Gateway.Serialization.TagExpired do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:skill_id, 1, type: :string, json_name: "skillId")
  field(:target_id, 2, type: :string, json_name: "targetId")
  field(:tag, 3, type: :string)
end

defmodule Gateway.Serialization.Death do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:unit_id, 1, type: :string, json_name: "unitId")
end

defmodule Gateway.Serialization.EnergyRegen do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:target_id, 1, type: :string, json_name: "targetId")
  field(:skill_id, 2, type: :string, json_name: "skillId")
  field(:amount, 3, type: :float)
end

defmodule Gateway.Serialization.StatOverride do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:target_id, 1, type: :string, json_name: "targetId")
  field(:stat_affected, 2, type: Gateway.Serialization.StatAffected, json_name: "statAffected")
end
