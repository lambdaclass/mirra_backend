defmodule Gateway.Serialization.WebSocketRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:request_type, 0)

  field(:get_user, 1, type: Gateway.Serialization.GetUser, json_name: "getUser", oneof: 0)

  field(:get_user_by_username, 2,
    type: Gateway.Serialization.GetUserByUsername,
    json_name: "getUserByUsername",
    oneof: 0
  )

  field(:create_user, 3,
    type: Gateway.Serialization.CreateUser,
    json_name: "createUser",
    oneof: 0
  )

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

  field(:fight_level, 7,
    type: Gateway.Serialization.FightLevel,
    json_name: "fightLevel",
    oneof: 0
  )

  field(:select_unit, 8,
    type: Gateway.Serialization.SelectUnit,
    json_name: "selectUnit",
    oneof: 0
  )

  field(:unselect_unit, 9,
    type: Gateway.Serialization.UnselectUnit,
    json_name: "unselectUnit",
    oneof: 0
  )

  field(:level_up_unit, 10,
    type: Gateway.Serialization.LevelUpUnit,
    json_name: "levelUpUnit",
    oneof: 0
  )

  field(:tier_up_unit, 11,
    type: Gateway.Serialization.TierUpUnit,
    json_name: "tierUpUnit",
    oneof: 0
  )

  field(:fuse_unit, 12, type: Gateway.Serialization.FuseUnit, json_name: "fuseUnit", oneof: 0)
  field(:equip_item, 13, type: Gateway.Serialization.EquipItem, json_name: "equipItem", oneof: 0)

  field(:unequip_item, 14,
    type: Gateway.Serialization.UnequipItem,
    json_name: "unequipItem",
    oneof: 0
  )

  field(:get_item, 15, type: Gateway.Serialization.GetItem, json_name: "getItem", oneof: 0)

  field(:level_up_item, 16,
    type: Gateway.Serialization.LevelUpItem,
    json_name: "levelUpItem",
    oneof: 0
  )
end

defmodule Gateway.Serialization.GetUser do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:user_id, 1, type: :string, json_name: "userId")
end

defmodule Gateway.Serialization.GetUserByUsername do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:username, 1, type: :string)
end

defmodule Gateway.Serialization.CreateUser do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:username, 1, type: :string)
end

defmodule Gateway.Serialization.GetCampaigns do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:user_id, 1, type: :string, json_name: "userId")
end

defmodule Gateway.Serialization.GetCampaign do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:campaign_number, 2, type: :uint32, json_name: "campaignNumber")
end

defmodule Gateway.Serialization.GetLevel do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:level_id, 2, type: :string, json_name: "levelId")
end

defmodule Gateway.Serialization.FightLevel do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:level_id, 2, type: :string, json_name: "levelId")
end

defmodule Gateway.Serialization.SelectUnit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:unit_id, 2, type: :string, json_name: "unitId")
  field(:slot, 3, type: :uint32)
end

defmodule Gateway.Serialization.UnselectUnit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:unit_id, 2, type: :string, json_name: "unitId")
end

defmodule Gateway.Serialization.LevelUpUnit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:unit_id, 2, type: :string, json_name: "unitId")
end

defmodule Gateway.Serialization.TierUpUnit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:unit_id, 2, type: :string, json_name: "unitId")
end

defmodule Gateway.Serialization.FuseUnit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:unit_id, 2, type: :string, json_name: "unitId")
  field(:consumed_units_ids, 3, repeated: true, type: :string, json_name: "consumedUnitsIds")
end

defmodule Gateway.Serialization.EquipItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:item_id, 2, type: :string, json_name: "itemId")
  field(:unit_id, 3, type: :string, json_name: "unitId")
end

defmodule Gateway.Serialization.UnequipItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:item_id, 2, type: :string, json_name: "itemId")
end

defmodule Gateway.Serialization.GetItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:item_id, 2, type: :string, json_name: "itemId")
end

defmodule Gateway.Serialization.LevelUpItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:user_id, 1, type: :string, json_name: "userId")
  field(:item_id, 2, type: :string, json_name: "itemId")
end

defmodule Gateway.Serialization.WebSocketResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:response_type, 0)

  field(:user, 1, type: Gateway.Serialization.User, oneof: 0)
  field(:unit, 2, type: Gateway.Serialization.Unit, oneof: 0)

  field(:unit_and_currencies, 3,
    type: Gateway.Serialization.UnitAndCurrencies,
    json_name: "unitAndCurrencies",
    oneof: 0
  )

  field(:item, 4, type: Gateway.Serialization.Item, oneof: 0)
  field(:campaigns, 5, type: Gateway.Serialization.Campaigns, oneof: 0)
  field(:campaign, 6, type: Gateway.Serialization.Campaign, oneof: 0)
  field(:level, 7, type: Gateway.Serialization.Level, oneof: 0)

  field(:battle_result, 8,
    type: Gateway.Serialization.BattleResult,
    json_name: "battleResult",
    oneof: 0
  )

  field(:error, 9, type: Gateway.Serialization.Error, oneof: 0)
end

defmodule Gateway.Serialization.User do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:id, 1, type: :string)
  field(:username, 2, type: :string)
  field(:currencies, 3, repeated: true, type: Gateway.Serialization.UserCurrency)
  field(:units, 4, repeated: true, type: Gateway.Serialization.Unit)
  field(:items, 5, repeated: true, type: Gateway.Serialization.Item)
end

defmodule Gateway.Serialization.UserCurrency do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:currency, 1, type: Gateway.Serialization.Currency)
  field(:amount, 2, type: :uint32)
end

defmodule Gateway.Serialization.Currency do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:name, 1, type: :string)
end

defmodule Gateway.Serialization.Unit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:id, 1, type: :string)
  field(:unit_level, 2, type: :uint32, json_name: "unitLevel")
  field(:tier, 3, type: :uint32)
  field(:rank, 4, type: :uint32)
  field(:selected, 5, type: :bool)
  field(:slot, 6, type: :uint32)
  field(:level_id, 7, type: :string, json_name: "levelId")
  field(:user_id, 8, type: :string, json_name: "userId")
  field(:character, 9, type: Gateway.Serialization.Character)
  field(:items, 10, repeated: true, type: Gateway.Serialization.Item)
end

defmodule Gateway.Serialization.UnitAndCurrencies do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:unit, 1, type: Gateway.Serialization.Unit)

  field(:user_currency, 2,
    repeated: true,
    type: Gateway.Serialization.UserCurrency,
    json_name: "userCurrency"
  )
end

defmodule Gateway.Serialization.Character do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:active, 1, type: :bool)
  field(:name, 2, type: :string)
  field(:faction, 3, type: :string)
  field(:rarity, 4, type: :uint32)
end

defmodule Gateway.Serialization.Item do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:id, 1, type: :string)
  field(:level, 2, type: :uint32)
  field(:template, 3, type: Gateway.Serialization.ItemTemplate)
  field(:user_id, 4, type: :string, json_name: "userId")
  field(:unit_id, 5, type: :string, json_name: "unitId")
end

defmodule Gateway.Serialization.ItemTemplate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:id, 1, type: :string)
  field(:name, 2, type: :string)
  field(:type, 3, type: :string)
end

defmodule Gateway.Serialization.Campaigns do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:campaigns, 1, repeated: true, type: Gateway.Serialization.Campaign)
end

defmodule Gateway.Serialization.Campaign do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:levels, 1, repeated: true, type: Gateway.Serialization.Level)
end

defmodule Gateway.Serialization.Level do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:id, 1, type: :string)
  field(:level_number, 2, type: :uint32, json_name: "levelNumber")
  field(:campaign, 3, type: :uint32)
  field(:units, 4, repeated: true, type: Gateway.Serialization.Unit)
end

defmodule Gateway.Serialization.BattleResult do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:result, 1, type: :string)
end

defmodule Gateway.Serialization.Error do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:reason, 1, type: :string)
end
