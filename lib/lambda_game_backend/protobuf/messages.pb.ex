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

defmodule LambdaGameBackend.Protobuf.Player do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :uint64
  field :speed, 2, type: :float
  field :position, 3, type: LambdaGameBackend.Protobuf.Position
  field :size, 4, type: :float
  field :life, 5, type: :uint64
end

defmodule LambdaGameBackend.Protobuf.Polygon do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :vertices, 1, repeated: true, type: LambdaGameBackend.Protobuf.Position
end

defmodule LambdaGameBackend.Protobuf.GameState.PlayersEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :key, 1, type: :uint64
  field :value, 2, type: LambdaGameBackend.Protobuf.Player
end

defmodule LambdaGameBackend.Protobuf.GameState.PolygonsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :key, 1, type: :uint64
  field :value, 2, type: LambdaGameBackend.Protobuf.Polygon
end

defmodule LambdaGameBackend.Protobuf.GameState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :players, 1,
    repeated: true,
    type: LambdaGameBackend.Protobuf.GameState.PlayersEntry,
    map: true

  field :polygons, 2,
    repeated: true,
    type: LambdaGameBackend.Protobuf.GameState.PolygonsEntry,
    map: true
end

defmodule LambdaGameBackend.Protobuf.Element do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :id, 1, type: :uint64
  field :type, 2, type: :string
  field :shape, 3, type: :string
  field :name, 4, type: :string
  field :position, 5, type: LambdaGameBackend.Protobuf.Position
  field :radius, 6, type: :float
  field :vertices, 7, repeated: true, type: LambdaGameBackend.Protobuf.Position
  field :is_colliding, 8, type: :bool, json_name: "isColliding"
end