defmodule DarkWorldsServer.Config.Games do
  import Ecto.Query

  alias DarkWorldsServer.Config.Games.Game
  alias DarkWorldsServer.Config.Games.Loot
  alias DarkWorldsServer.Config.Games.LootEffect
  alias DarkWorldsServer.Config.Games.ZoneModification
  alias DarkWorldsServer.Config.Games.ZoneModificationEffect
  alias DarkWorldsServer.Repo

  #########
  # Games #
  #########

  def insert_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  # We only have one game for now
  def get_game(), do: Repo.one(from(g in Game)) |> Repo.preload(zone_modifications: :outside_radius_effects)

  def delete_all_games(), do: Repo.delete_all(Game)

  #####################
  # ZoneModifications #
  #####################
  # We don't need inserts as they are handled by the game assoc

  def all_zone_modifications(), do: Repo.all(ZoneModification)

  def delete_all_zone_modifications(), do: Repo.delete_all(ZoneModification)

  ###########################
  # ZoneModificationEffects #
  ###########################

  def insert_zone_modification_effect(attrs \\ %{}) do
    %ZoneModificationEffect{}
    |> ZoneModificationEffect.changeset(attrs)
    |> Repo.insert()
  end

  def delete_all_zone_modification_effects(), do: Repo.delete_all(ZoneModificationEffect)

  ########
  # Loot #
  ########

  def insert_loot(attrs \\ %{}) do
    %Loot{}
    |> Loot.changeset(attrs)
    |> Repo.insert()
  end

  def get_loot(id), do: Repo.get(Loot, id) |> Repo.preload(:effects)

  def get_loots(), do: Repo.all(Loot) |> Repo.preload(:effects)

  def get_loot_by_name(name), do: Repo.one(from(l in Loot, where: l.name == ^name))

  def delete_all_loots(), do: Repo.delete_all(Loot)

  ###############
  # LootEffects #
  ###############

  def insert_loot_effect(attrs \\ %{}) do
    %LootEffect{}
    |> LootEffect.changeset(attrs)
    |> Repo.insert()
  end

  def delete_all_loot_effects(), do: Repo.delete_all(LootEffect)
end
