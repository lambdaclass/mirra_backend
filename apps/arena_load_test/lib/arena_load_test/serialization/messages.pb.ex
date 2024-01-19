defmodule ArenaLoadTest.Serialization.Direction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:x, 1, type: :float)
  field(:y, 2, type: :float)
end

defmodule ArenaLoadTest.Serialization.Position do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:x, 1, type: :float)
  field(:y, 2, type: :float)
end

defmodule ArenaLoadTest.Serialization.GameEvent do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:event, 0)

  field(:joined, 1, type: ArenaLoadTest.Serialization.GameJoined, oneof: 0)
  field(:update, 2, type: ArenaLoadTest.Serialization.GameState, oneof: 0)
end

defmodule ArenaLoadTest.Serialization.GameJoined do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:player_id, 1, type: :uint64, json_name: "playerId")
  field(:config, 2, type: ArenaLoadTest.Serialization.Configuration)
end

defmodule ArenaLoadTest.Serialization.Configuration do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:game, 1, type: ArenaLoadTest.Serialization.ConfigGame)
  field(:map, 2, type: ArenaLoadTest.Serialization.ConfigMap)
end

defmodule ArenaLoadTest.Serialization.ConfigGame do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:tick_rate_ms, 1, type: :float, json_name: "tickRateMs")
end

defmodule ArenaLoadTest.Serialization.ConfigMap do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:radius, 1, type: :float)
end

defmodule ArenaLoadTest.Serialization.GameState.PlayersEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameState.ProjectilesEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:game_id, 1, type: :string, json_name: "gameId")

  field(:players, 2,
    repeated: true,
    type: ArenaLoadTest.Serialization.GameState.PlayersEntry,
    map: true
  )

  field(:projectiles, 3,
    repeated: true,
    type: ArenaLoadTest.Serialization.GameState.ProjectilesEntry,
    map: true
  )

  field(:player_timestamp, 4, type: :int64, json_name: "playerTimestamp")
  field(:server_timestamp, 5, type: :int64, json_name: "serverTimestamp")
end

defmodule ArenaLoadTest.Serialization.Entity do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:aditional_info, 0)

  field(:id, 1, type: :uint64)
  field(:category, 2, type: :string)
  field(:shape, 3, type: :string)
  field(:name, 4, type: :string)
  field(:position, 5, type: ArenaLoadTest.Serialization.Position)
  field(:radius, 6, type: :float)
  field(:vertices, 7, repeated: true, type: ArenaLoadTest.Serialization.Position)
  field(:is_colliding, 8, type: :bool, json_name: "isColliding")
  field(:collides_with, 9, repeated: true, type: :uint64, json_name: "collidesWith")
  field(:speed, 10, type: :float)
  field(:direction, 11, type: ArenaLoadTest.Serialization.Direction)
  field(:player, 12, type: ArenaLoadTest.Serialization.Player, oneof: 0)
  field(:projectile, 13, type: ArenaLoadTest.Serialization.Projectile, oneof: 0)
  field(:obstacle, 14, type: ArenaLoadTest.Serialization.Obstacle, oneof: 0)
end

defmodule ArenaLoadTest.Serialization.Player do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:health, 1, type: :uint64)
end

defmodule ArenaLoadTest.Serialization.Projectile do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:damage, 1, type: :uint64)
  field(:owner_id, 2, type: :uint64, json_name: "ownerId")
end

defmodule ArenaLoadTest.Serialization.Obstacle do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:color, 1, type: :string)
end

defmodule ArenaLoadTest.Serialization.Move do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:direction, 1, type: ArenaLoadTest.Serialization.Direction)
end

defmodule ArenaLoadTest.Serialization.Attack do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:skill, 1, type: :string)
end

defmodule ArenaLoadTest.Serialization.GameAction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:action_type, 0)

  field(:move, 1, type: ArenaLoadTest.Serialization.Move, oneof: 0)
  field(:attack, 2, type: ArenaLoadTest.Serialization.Attack, oneof: 0)
  field(:timestamp, 3, type: :int64)
end
