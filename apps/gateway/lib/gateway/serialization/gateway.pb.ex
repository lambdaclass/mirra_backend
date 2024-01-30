defmodule Gateway.Serialization.WebSocketRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof :request_type, 0

  field :get_user, 1, type: Gateway.Serialization.GetUser, json_name: "getUser", oneof: 0
  field :get_user_id, 2, type: Gateway.Serialization.GetUserId, json_name: "getUserId", oneof: 0
  field :create_user, 3, type: Gateway.Serialization.CreateUser, json_name: "createUser", oneof: 0

  field :get_campaigns, 4,
    type: Gateway.Serialization.GetCampaigns,
    json_name: "getCampaigns",
    oneof: 0

  field :get_campaign, 5,
    type: Gateway.Serialization.GetCampaign,
    json_name: "getCampaign",
    oneof: 0

  field :get_level, 6, type: Gateway.Serialization.GetLevel, json_name: "getLevel", oneof: 0
  field :fight_level, 7, type: Gateway.Serialization.FightLevel, json_name: "fightLevel", oneof: 0
  field :select_unit, 8, type: Gateway.Serialization.SelectUnit, json_name: "selectUnit", oneof: 0

  field :unselect_unit, 9,
    type: Gateway.Serialization.UnselectUnit,
    json_name: "unselectUnit",
    oneof: 0

  field :equip_item, 10, type: Gateway.Serialization.EquipItem, json_name: "equipItem", oneof: 0

  field :unequip_item, 11,
    type: Gateway.Serialization.UnequipItem,
    json_name: "unequipItem",
    oneof: 0

  field :get_item, 12, type: Gateway.Serialization.GetItem, json_name: "getItem", oneof: 0

  field :level_up_item, 13,
    type: Gateway.Serialization.LevelUpItem,
    json_name: "levelUpItem",
    oneof: 0
end

defmodule Gateway.Serialization.GetUser do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :user_id, 1, type: :string, json_name: "userId"
end

defmodule Gateway.Serialization.GetUserId do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :username, 1, type: :string
end

defmodule Gateway.Serialization.CreateUser do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :usernme, 1, type: :string
end

defmodule Gateway.Serialization.GetCampaigns do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :user_id, 1, type: :string, json_name: "userId"
end

defmodule Gateway.Serialization.GetCampaign do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :user_id, 1, type: :string, json_name: "userId"
  field :number, 2, type: :uint32
end

defmodule Gateway.Serialization.GetLevel do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :user_id, 1, type: :string, json_name: "userId"
  field :level_id, 2, type: :string, json_name: "levelId"
end

defmodule Gateway.Serialization.FightLevel do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :user_id, 1, type: :string, json_name: "userId"
  field :level_id, 2, type: :string, json_name: "levelId"
end

defmodule Gateway.Serialization.SelectUnit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :user_id, 1, type: :string, json_name: "userId"
  field :unit_id, 2, type: :string, json_name: "unitId"
  field :slot, 3, type: :uint32
end

defmodule Gateway.Serialization.UnselectUnit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :user_id, 1, type: :string, json_name: "userId"
  field :unit_id, 2, type: :string, json_name: "unitId"
end

defmodule Gateway.Serialization.EquipItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :user_id, 1, type: :string, json_name: "userId"
  field :item_id, 2, type: :string, json_name: "itemId"
  field :unit_id, 3, type: :string, json_name: "unitId"
end

defmodule Gateway.Serialization.UnequipItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :user_id, 1, type: :string, json_name: "userId"
  field :item_id, 2, type: :string, json_name: "itemId"
end

defmodule Gateway.Serialization.GetItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :user_id, 1, type: :string, json_name: "userId"
  field :item_id, 2, type: :string, json_name: "itemId"
end

defmodule Gateway.Serialization.LevelUpItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :user_id, 1, type: :string, json_name: "userId"
  field :item_id, 2, type: :string, json_name: "itemId"
end