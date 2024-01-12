defmodule Arena.Protobuf.Direction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :x, 1, type: :float
  field :y, 2, type: :float
end

defmodule Arena.Protobuf.Position do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :x, 1, type: :float
  field :y, 2, type: :float
end

defmodule Arena.Protobuf.GameState.EntitiesEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :key, 1, type: :uint64
  field :value, 2, type: Arena.Protobuf.Entity
end

defmodule Arena.Protobuf.GameState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :game_id, 1, type: :string, json_name: "gameId"
  field :entities, 2, repeated: true, type: Arena.Protobuf.GameState.EntitiesEntry, map: true
end

defmodule Arena.Protobuf.Entity do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:aditional_info, 0)

  field :id, 1, type: :uint64
  field :category, 2, type: :string
  field :shape, 3, type: :string
  field :name, 4, type: :string
  field :position, 5, type: Arena.Protobuf.Position
  field :radius, 6, type: :float
  field :vertices, 7, repeated: true, type: Arena.Protobuf.Position
  field :is_colliding, 8, type: :bool, json_name: "isColliding"
  field :speed, 9, type: :float
  field :direction, 10, type: Arena.Protobuf.Direction
  field :player, 11, type: Arena.Protobuf.Player, oneof: 0
  field :projectile, 12, type: Arena.Protobuf.Projectile, oneof: 0
  field :obstacle, 13, type: Arena.Protobuf.Obstacle, oneof: 0
end

defmodule Arena.Protobuf.Player do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :health, 1, type: :uint64
end

defmodule Arena.Protobuf.Projectile do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :damage, 1, type: :uint64
  field :owner_id, 2, type: :uint64, json_name: "ownerId"
end

defmodule Arena.Protobuf.Obstacle do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :color, 1, type: :string
end

defmodule Arena.Protobuf.Move do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :direction, 1, type: Arena.Protobuf.Direction
end

defmodule Arena.Protobuf.Attack do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :skill, 1, type: :string
end

defmodule Arena.Protobuf.GameAction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:action_type, 0)

  field :move, 1, type: Arena.Protobuf.Move, oneof: 0
  field :attack, 2, type: Arena.Protobuf.Attack, oneof: 0
end
