defmodule Arena.Serialization.Direction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :x, 1, type: :float
  field :y, 2, type: :float
end

defmodule Arena.Serialization.Position do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :x, 1, type: :float
  field :y, 2, type: :float
end

defmodule Arena.Serialization.GameEvent do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:event, 0)

  field :joined, 1, type: Arena.Serialization.GameJoined, oneof: 0
  field :update, 2, type: Arena.Serialization.GameState, oneof: 0
end

defmodule Arena.Serialization.GameJoined do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :player_id, 1, type: :uint64, json_name: "playerId"
  field :config, 2, type: Arena.Serialization.Configuration
end

defmodule Arena.Serialization.Configuration do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :game, 1, type: Arena.Serialization.ConfigGame
  field :map, 2, type: Arena.Serialization.ConfigMap
end

defmodule Arena.Serialization.ConfigGame do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :tick_rate_ms, 1, type: :float, json_name: "tickRateMs"
end

defmodule Arena.Serialization.ConfigMap do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :radius, 1, type: :float
end

defmodule Arena.Serialization.GameState.PlayersEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :key, 1, type: :uint64
  field :value, 2, type: Arena.Serialization.Entity
end

defmodule Arena.Serialization.GameState.ProjectilesEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :key, 1, type: :uint64
  field :value, 2, type: Arena.Serialization.Entity
end

defmodule Arena.Serialization.GameState.PlayerTimestampsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :key, 1, type: :uint64
  field :value, 2, type: :int64
end

defmodule Arena.Serialization.GameState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :game_id, 1, type: :string, json_name: "gameId"
  field :players, 2, repeated: true, type: Arena.Serialization.GameState.PlayersEntry, map: true

  field :projectiles, 3,
    repeated: true,
    type: Arena.Serialization.GameState.ProjectilesEntry,
    map: true

  field :player_timestamps, 4,
    repeated: true,
    type: Arena.Serialization.GameState.PlayerTimestampsEntry,
    json_name: "playerTimestamps",
    map: true

  field :server_timestamp, 5, type: :int64, json_name: "serverTimestamp"
end

defmodule Arena.Serialization.Entity do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:aditional_info, 0)

  field :id, 1, type: :uint64
  field :category, 2, type: :string
  field :shape, 3, type: :string
  field :name, 4, type: :string
  field :position, 5, type: Arena.Serialization.Position
  field :radius, 6, type: :float
  field :vertices, 7, repeated: true, type: Arena.Serialization.Position
  field :is_colliding, 8, type: :bool, json_name: "isColliding"
  field :collides_with, 9, repeated: true, type: :uint64, json_name: "collidesWith"
  field :speed, 10, type: :float
  field :direction, 11, type: Arena.Serialization.Direction
  field :player, 12, type: Arena.Serialization.Player, oneof: 0
  field :projectile, 13, type: Arena.Serialization.Projectile, oneof: 0
  field :obstacle, 14, type: Arena.Serialization.Obstacle, oneof: 0
end

defmodule Arena.Serialization.Player do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :health, 1, type: :uint64
end

defmodule Arena.Serialization.Projectile do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :damage, 1, type: :uint64
  field :owner_id, 2, type: :uint64, json_name: "ownerId"
end

defmodule Arena.Serialization.Obstacle do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :color, 1, type: :string
end

defmodule Arena.Serialization.Move do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :direction, 1, type: Arena.Serialization.Direction
end

defmodule Arena.Serialization.Attack do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :skill, 1, type: :string
end

defmodule Arena.Serialization.GameAction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:action_type, 0)

  field :move, 1, type: Arena.Serialization.Move, oneof: 0
  field :attack, 2, type: Arena.Serialization.Attack, oneof: 0
  field :timestamp, 3, type: :int64
end
