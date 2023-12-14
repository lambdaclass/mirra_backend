defmodule DarkWorldsServer.Config.Game do
  import Ecto.Query

  alias DarkWorldsServer.Config.Game.Loot
  alias DarkWorldsServer.Config.Game.LootEffect
  alias DarkWorldsServer.Repo

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

  def get_loot(id), do: Repo.get(Loot, id)
  def get_loot_by_name(name), do: Repo.one(from(l in Loot, where: l.name == ^name))

  def get_loot_effects(id), do: Repo.get(LootEffect, id)

  def delete_all_loot(), do: Repo.delete_all(Loot)
  def delete_all_loot_effects(), do: Repo.delete_all(LootEffect)
end
