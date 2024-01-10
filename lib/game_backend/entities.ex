defmodule GameBackend.Entities do

  def new_player(id) do
    %{
      id: id,
      category: :player,
      shape: :circle,
      name: "Player" <> Integer.to_string(id),
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 50.0,
      vertices: [],
      speed: 10.0,
      direction: %{
        x: 0.0,
        y: 0.0
      }
    }
  end

  def new_projectile(id, position, direction) do
    %{
      id: id,
      category: :projectile,
      shape: :circle,
      name: "Projectile" <> Integer.to_string(id),
      position: position,
      radius: 10.0,
      vertices: [],
      speed: 30.0,
      direction: direction
    }
  end

  def encode(entity) do
    GameBackend.Protobuf.Entity.encode(%GameBackend.Protobuf.Entity{
      id: entity.id,
      category: to_string(entity.category),
      shape: to_string(entity.shape),
      name: "Entity" <> Integer.to_string(entity.id),
      position: %GameBackend.Protobuf.Position{
        x: entity.position.x,
        y: entity.position.y
      },
      radius: entity.radius,
      vertices:
        Enum.map(entity.vertices, fn vertex ->
          %GameBackend.Protobuf.Position{
            x: vertex.x,
            y: vertex.y
          }
        end),
      is_colliding: entity.is_colliding,
    })
  end
end
