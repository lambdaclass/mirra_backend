defmodule DarkWorldsServer.Repo.Migrations.ChangePositionIntegersToFloats do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      modify :base_speed, :float, from: :integer
      modify :base_size, :float, from: :integer
    end

    alter table(:projectiles) do
      modify :base_speed, :float, from: :integer
      modify :base_size, :float, from: :integer
      modify :max_distance, :float, from: :integer
    end

    alter table(:loots) do
      modify :size, :float, from: :integer
    end

    alter table(:games) do
      modify :width, :float, from: :integer
      modify :height, :float, from: :integer
      modify :zone_starting_radius, :float, from: :integer
    end

    alter table(:zone_modifications) do
      modify :min_radius, :float, from: :integer
      modify :max_radius, :float, from: :integer
    end
  end
end
