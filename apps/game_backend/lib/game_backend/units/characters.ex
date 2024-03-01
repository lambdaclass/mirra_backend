defmodule GameBackend.Units.Characters do
  @moduledoc """
  Operations done to the Configuration storage related to Characters.
  """

  import Ecto.Query
  alias Ecto.Multi
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

  def update_character(character, attrs \\ %{}) do
    character
    |> Character.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Inserts all characters into the database. If another one already exists with
  the same name and game_id, it updates it instead.
  """
  def upsert_characters(attrs_list) do
    Enum.reduce(attrs_list, Multi.new(), fn attrs, multi ->
      changeset = Character.changeset(%Character{}, attrs)

      Multi.insert(multi, attrs.name, changeset,
        on_conflict: [
          set: Enum.into(attrs, [])
        ],
        conflict_target: [:name, :game_id]
      )
    end)
    |> Repo.transaction()
  end

  def get_character(id), do: Repo.get(Character, id) |> Repo.preload(:skills)

  def get_characters(), do: Repo.all(Character) |> Repo.preload(:skills)

  def get_character_by_name(name), do: Repo.one(from(c in Character, where: c.name == ^name)) |> Repo.preload([:basic_skill, :ultimate_skill])

  def delete_all_characters(), do: Repo.delete_all(Character)

  def get_characters_by_rank(rank),
    do: Repo.all(from(c in Character, where: ^rank in c.ranks_dropped_in))

  def get_characters_by_rank_and_faction(rank, factions),
    do:
      Repo.all(
        from(c in Character, where: ^rank in c.ranks_dropped_in and c.faction in ^factions)
      )
end
