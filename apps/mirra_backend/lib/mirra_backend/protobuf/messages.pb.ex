defmodule MirraBackend.Protobuf.Direction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:x, 1, type: :float)
  field(:y, 2, type: :float)
end

defmodule MirraBackend.Protobuf.Position do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:x, 1, type: :float)
  field(:y, 2, type: :float)
end

defmodule MirraBackend.Protobuf.GameState.EntitiesEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: MirraBackend.Protobuf.Entity)
end

defmodule MirraBackend.Protobuf.GameState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:game_id, 1, type: :string, json_name: "gameId")

  field(:entities, 2,
    repeated: true,
    type: MirraBackend.Protobuf.GameState.EntitiesEntry,
    map: true
  )
end

defmodule MirraBackend.Protobuf.Entity do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:id, 1, type: :uint64)
  field(:category, 2, type: :string)
  field(:shape, 3, type: :string)
  field(:name, 4, type: :string)
  field(:position, 5, type: MirraBackend.Protobuf.Position)
  field(:radius, 6, type: :float)
  field(:vertices, 7, repeated: true, type: MirraBackend.Protobuf.Position)
  field(:is_colliding, 8, type: :bool, json_name: "isColliding")
  field(:speed, 9, type: :float)
  field(:direction, 10, type: MirraBackend.Protobuf.Direction)
end

defmodule MirraBackend.Protobuf.Move do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:direction, 1, type: MirraBackend.Protobuf.Direction)
end

defmodule MirraBackend.Protobuf.Attack do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:skill, 1, type: :string)
end

defmodule MirraBackend.Protobuf.GameAction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:action_type, 0)

  field(:move, 1, type: MirraBackend.Protobuf.Move, oneof: 0)
  field(:attack, 2, type: MirraBackend.Protobuf.Attack, oneof: 0)
end
