defmodule GameBackend.Repo.Migrations.AddShapeFieldForMechanics do
  use Ecto.Migration

  def up do
    alter table(:mechanics) do
      add :shape, :string
      add :vertices, {:array, :map}
    end

    execute("""
    UPDATE mechanics mechanic
    SET shape = 'circle', vertices = '{}'::jsonb[]
    WHERE mechanic.type = 'spawn_pool';
    """)
  end

  def down do
    alter table(:mechanics) do
      remove :shape, :string
      remove :vertices, {:array, :map}
    end
  end
end
