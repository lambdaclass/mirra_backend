defmodule GameBackend.Gacha do
  @moduledoc """
  Operations for the Gacha system.
  """

  import Ecto.Query
  alias GameBackend.Gacha.Box
  alias GameBackend.Repo
  alias GameBackend.Units

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
    case Repo.get(Box, id) |> Repo.preload(:character_drop_rates) do
      nil -> {:error, :not_found}
      box -> {:ok, box}
    end
  end

  @doc """
  Gets a Box by name.
  """
  def get_box_by_name(name) do
    case Repo.one(from(b in Box, where: b.name == ^name))
         |> Repo.preload(:character_drop_rates) do
      nil -> {:error, :not_found}
      box -> {:ok, box}
    end
  end

  @doc """
  Gets all Boxes.
  """
  def get_boxes(), do: Repo.all(Box) |> Repo.preload(:character_drop_rates)

  @doc """
  Get a character from the given box and add it as a new unit for the user.
  Returns the new unit that was created.
  """
  def pull(user_id, box, unit_params \\ %{unit_level: 1, tier: 1, rank: 1, selected: false}) do
    character_drop_rates = box.character_drop_rates |> Enum.sort(&(&1.weight >= &2.weight))

    total_weight =
      Enum.reduce(character_drop_rates, 0, fn drop_rate, acc -> drop_rate.weight + acc end)

    character_id =
      Enum.reduce_while(character_drop_rates, Enum.random(1..total_weight), fn drop_rate,
                                                                               acc_weight ->
        acc_weight = acc_weight - drop_rate.weight
        if acc_weight <= 0, do: {:halt, drop_rate.character_id}, else: {:cont, acc_weight}
      end)

    params = Map.merge(unit_params, %{character_id: character_id, user_id: user_id})

    case Units.insert_unit(params) do
      {:error, reason} -> {:error, reason}
      {:ok, unit} -> {:ok, unit}
    end
  end
end
