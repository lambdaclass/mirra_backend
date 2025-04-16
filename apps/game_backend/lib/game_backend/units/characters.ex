defmodule GameBackend.Units.Characters do
  @moduledoc """
  Operations related to Characters.
  """

  import Ecto.Query
  alias GameBackend.Configuration.Version
  alias Ecto.Multi
  alias GameBackend.Repo
  alias GameBackend.Units.UnitSkin
  alias GameBackend.Units.Characters.Character
  alias GameBackend.Units.Characters.Skin

  ##############
  # Characters #
  ##############

  @doc """
  Inserts a Character.

  ## Examples

      iex> insert_character(%{field: value})
      {:ok, %Character{}}

      iex> insert_character(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def insert_character(attrs \\ %{}) do
    %Character{}
    |> Character.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Update a Character.

  ## Examples

      iex> update_character(%Character{name: "Muflus"}, %{name: "H4ck"})
      {:ok, %Character{name: "H4ck"}}
  """
  def update_character(character, attrs \\ %{}) do
    character
    |> Character.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Inserts all Characters into the database. If another one already exists with
  the same name and game_id, it updates it instead.
  """
  def upsert_characters(attrs_list) do
    Enum.reduce(attrs_list, Multi.new(), fn attrs, multi ->
      changeset = Character.changeset(%Character{}, attrs)

      Multi.insert(multi, attrs.name, changeset,
        on_conflict: [
          set: Enum.into(attrs, [])
        ],
        conflict_target: [:name, :game_id, :version_id]
      )
    end)
    |> Repo.transaction()
  end

  @doc """
  Deletes a Character.

  ## Examples

      iex> delete_character(character)
      {:ok, %character{}}

      iex> delete_character(character)
      {:error, %Ecto.Changeset{}}

  """
  def delete_character(%Character{} = character) do
    Repo.delete(character)
  end

  @doc """
  Get a Character by id.

  ## Examples

      iex> get_character(item_template_id)
      {:ok, %Character{}}

      iex> get_character(wrong_id)
      {:error, :not_found}
  """
  def get_character(id), do: Repo.get(Character, id) |> Repo.preload([:basic_skill, :ultimate_skill, :dash_skill])

  @doc """
  Get all Characters.

  ## Examples
      iex> get_characters()
      [%Character{}]
  """
  def get_characters(), do: Repo.all(Character) |> Repo.preload([:basic_skill, :ultimate_skill])

  @doc """
  Get a Character by name.

  ## Examples

      iex> get_character(character_name)
      %Character{}

      iex> get_character(wrong_character_name)
      nil
  """
  def get_character_by_name(name),
    do: Repo.one(from(c in Character, where: c.name == ^name)) |> Repo.preload([:basic_skill, :ultimate_skill])

  @doc """
  Get a Character's ID by name and game_id.

  ## Examples

      iex> get_character(character_name, game_id)
      "character_name_id"

      iex> get_character(wrong_character_name, game_id)
      nil
  """
  def get_character_id_by_name_and_game_id(name, game_id) do
    if game_id == GameBackend.Utils.get_game_id(:champions_of_mirra) do
      Repo.one(from(c in Character, where: c.name == ^name and c.game_id == ^game_id, select: c.id))
    else
      current_version_id = Repo.one(from(v in Version, where: v.current, select: v.id))

      Repo.one(
        from(c in Character,
          where: c.name == ^name and c.game_id == ^game_id and c.version_id == ^current_version_id,
          select: c.id
        )
      )
    end
  end

  @doc """
  Delete all Characters from the database.
  """
  def delete_all_characters(), do: Repo.delete_all(Character)

  @doc """
  Get all Characters with given quality.

  ## Examples

      iex> get_characters_by_quality(Champions.Units.get_quality(:epic))
      [%Character%{quality: 5}]
  """
  def get_characters_by_quality(quality), do: Repo.all(from(c in Character, where: ^quality == c.quality))

  @doc """
  Get all Characters with given rank_dropped_in.

  ## Examples

      iex> get_characters_by_rank(Champions.Units.get_rank(:star4))
      [%Character%{rank: 4}]
  """
  def get_characters_by_rank(rank), do: Repo.all(from(c in Character, where: ^rank in c.ranks_dropped_in))

  @doc """
  Get all Characters with given rank_dropped_in.

  ## Examples

  iex> get_characters_by_rank_and_faction(Champions.Units.get_rank(:star4), "Kaline")
  [%Character%{rank: 4, faction: "Kaline"}]
  """
  def get_characters_by_rank_and_faction(rank, factions),
    do: Repo.all(from(c in Character, where: ^rank in c.ranks_dropped_in and c.faction in ^factions))

  @doc """
  Get all Characters for Curse of Mirra game.

  ## Examples

  iex> get_curse_characters()
  [%Character%{game_id: 1, name: "Muflus"}, ...]
  """
  def get_curse_characters_by_version(version_id) do
    curse_id = GameBackend.Utils.get_game_id(:curse_of_mirra)

    q =
      from(c in Character,
        where: ^curse_id == c.game_id and ^version_id == c.version_id,
        preload: [
          basic_skill: [mechanics: [:on_arrival_mechanic, :on_explode_mechanics, :parent_mechanic]],
          ultimate_skill: [mechanics: [:on_arrival_mechanic, :on_explode_mechanics, :parent_mechanic]],
          dash_skill: [mechanics: [:on_arrival_mechanic, :on_explode_mechanics, :parent_mechanic]]
        ]
      )

    Repo.all(q)
  end

  @doc """
  Inserts a Skin.
  ## Examples
      iex> insert_skin(%{field: value})
      {:ok, %Skin{}}
      iex> insert_skin(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def insert_skin(attrs \\ %{}) do
    %Skin{}
    |> Skin.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a Skin.
  ## Examples
      iex> insert_skin(%{field: value})
      {:ok, %Skin{}}
      iex> insert_skin(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def get_skin(id) do
    Repo.one(Skin, id)
    |> case do
      nil -> {:error, :not_found}
      skin -> {:ok, skin}
    end
  end

  def insert_unit_skin(attrs) do
    %UnitSkin{}
    |> UnitSkin.changeset(attrs)
    |> Repo.insert()
  end
end
