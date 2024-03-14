defmodule GameBackend.Units.Characters do
  @moduledoc """
  Operations done to the Configuration storage related to Characters.
  """

  import Ecto.Query
  alias GameBackend.Repo
  alias GameBackend.Units.Characters.Character

  ##############
  # Characters #
  ##############

  def insert_character(attrs \\ %{}) do
    %Character{}
    |> Character.changeset(attrs)
    |> Repo.insert()
  end

  def get_character(id),
    do: Repo.get(Character, id) |> Repo.preload([:basic_skill, :ultimate_skill])

  def get_characters(), do: Repo.all(Character) |> Repo.preload([:basic_skill, :ultimate_skill])

  def get_character_by_name(name), do: Repo.one(from(c in Character, where: c.name == ^name))

  def delete_all_characters(), do: Repo.delete_all(Character)

  def get_characters_by_rank(rank),
    do: Repo.all(from(c in Character, where: ^rank in c.ranks_dropped_in))

  def get_characters_by_rank_and_faction(rank, factions),
    do: Repo.all(from(c in Character, where: ^rank in c.ranks_dropped_in and c.faction in ^factions))
end
