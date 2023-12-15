defmodule DarkWorldsServer.Config.Games do
  import Ecto.Query

  alias DarkWorldsServer.Config.Games.Game
  alias DarkWorldsServer.Config.Games.Loot
  alias DarkWorldsServer.Config.Games.LootEffect
  alias DarkWorldsServer.Config.Games.ZoneModification
  alias DarkWorldsServer.Config.Games.ZoneModificationEffect
  alias DarkWorldsServer.Repo

  def insert_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  def insert_zone_modification_effect(attrs \\ %{}) do
    %ZoneModificationEffect{}
    |> ZoneModificationEffect.changeset(attrs)
    |> Repo.insert()
  end

  def insert_loot(attrs \\ %{}) do
    %Loot{}
    |> Loot.changeset(attrs)
    |> Repo.insert()
  end

  def insert_loot_effect(attrs \\ %{}) do
    %LootEffect{}
    |> LootEffect.changeset(attrs)
    |> Repo.insert()
  end

  # We only have one game for now
  def get_game(), do: Repo.one(from(g in Game)) |> Repo.preload(zone_modifications: :outside_radius_effects)

  def get_zone_modification(id), do: Repo.get(ZoneModification, id) |> Repo.preload(:outside_radius_effects)

  def get_loot(id), do: Repo.get(Loot, id)
  def get_loot_by_name(name), do: Repo.one(from(l in Loot, where: l.name == ^name))

  def get_loot_effects(id), do: Repo.get(LootEffect, id)

  def all_zone_modifications(), do: Repo.all(ZoneModification)

  def delete_all_games(), do: Repo.delete_all(Game)
  def delete_all_zone_modifications(), do: Repo.delete_all(ZoneModification)
  def delete_all_zone_modification_effects(), do: Repo.delete_all(ZoneModificationEffect)
  def delete_all_loots(), do: Repo.delete_all(Loot)
  def delete_all_loot_effects(), do: Repo.delete_all(LootEffect)
end
