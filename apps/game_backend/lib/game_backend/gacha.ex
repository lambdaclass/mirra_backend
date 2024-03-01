defmodule GameBackend.Gacha do
  @moduledoc """
  Operations for the Gacha system.
  """

  import Ecto.Query
  alias GameBackend.Gacha.Box
  alias GameBackend.Repo
  alias GameBackend.Units.Characters

  @doc """
  Inserts a Box.
  """
  def insert_box(attrs) do
    %Box{}
    |> Box.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a Box by id.
  """
  def get_box(id) do
    case Repo.get(Box, id) do
      nil -> {:error, :not_found}
      box -> {:ok, box}
    end
  end

  @doc """
  Gets a Box by name.
  """
  def get_box_by_name(name) do
    case Repo.one(from(b in Box, where: b.name == ^name, preload: [cost: :currency])) do
      nil -> {:error, :not_found}
      box -> {:ok, box}
    end
  end

  @doc """
  Gets all Boxes.
  """
  def get_boxes(), do: Repo.all(from b in Box, preload: [cost: :currency])

  @doc """
  Get a character from the given box. Does not add as unit (that logic is left to game apps)
  """
  def pull_box(box) do
    total_weight =
      Enum.reduce(box.rank_weights, 0, fn rank_weight, acc -> rank_weight.weight + acc end)

    rank =
      Enum.reduce_while(box.rank_weights, Enum.random(1..total_weight), fn rank_weight,
                                                                           acc_weight ->
        acc_weight = acc_weight - rank_weight.weight
        if acc_weight <= 0, do: {:halt, rank_weight.rank}, else: {:cont, acc_weight}
      end)

    characters =
      if is_nil(box.factions),
        do: Characters.get_characters_by_rank(rank),
        else: Characters.get_characters_by_rank_and_faction(rank, box.factions)

    if Enum.empty?(characters),
      do: {:error, :no_character_found},
      else: {:ok, {rank, Enum.random(characters)}}
  end
end
