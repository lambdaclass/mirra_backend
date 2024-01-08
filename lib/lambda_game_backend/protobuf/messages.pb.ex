defmodule LambdaGameBackend.Protobuf.Direction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :x, 1, type: :float
  field :y, 2, type: :float
end

defmodule LambdaGameBackend.Protobuf.Position do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :x, 1, type: :float
  field :y, 2, type: :float
end

defmodule LambdaGameBackend.Protobuf.GameState.EntitiesEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :key, 1, type: :uint64
  field :value, 2, type: LambdaGameBackend.Protobuf.Entity
end

defmodule LambdaGameBackend.Protobuf.GameState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :entities, 1,
    repeated: true,
    type: LambdaGameBackend.Protobuf.GameState.EntitiesEntry,
    map: true
end

defmodule LambdaGameBackend.Protobuf.Entity do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :uint64
  field :category, 2, type: :string
  field :shape, 3, type: :string
  field :name, 4, type: :string
  field :position, 5, type: LambdaGameBackend.Protobuf.Position
  field :radius, 6, type: :float
  field :vertices, 7, repeated: true, type: LambdaGameBackend.Protobuf.Position
  field :is_colliding, 8, type: :bool, json_name: "isColliding"
  field :speed, 9, type: :float
end