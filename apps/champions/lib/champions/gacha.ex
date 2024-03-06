defmodule Champions.Gacha do
  @moduledoc """
  Gacha logic for Champions of Mirra.
  """

  alias GameBackend.Gacha
  alias GameBackend.Transaction
  alias GameBackend.Users
  alias GameBackend.Users.Currencies
  alias GameBackend.Units
  alias GameBackend.Repo
  alias Ecto.Multi

  @doc """
  Gets a Box by id.
  """
  def get_box(id), do: Gacha.get_box(id)

  @doc """
  Gets all Boxes.
  """
  def get_boxes(), do: Gacha.get_boxes()

  @doc """
  Get a character from the given box and add it as a new unit for the user.

  Returns a map with the new created unit and the user's new state (mainly for their currency).
  """
  def summon(user_id, box_id) do
    with {:user_exists, true} <- {:user_exists, Users.exists?(user_id)},
         {:get_box, {:ok, box}} <- {:get_box, Gacha.get_box(box_id)},
         {:can_afford, true} <-
           {:can_afford, Currencies.can_afford(user_id, box.cost)},
         {:pull, {:ok, {rank, character}}} <- {:pull, Gacha.pull_box(box)} do
      params = %{
        character_id: character.id,
        user_id: user_id,
        rank: rank,
        level: 1,
        tier: 1,
        selected: false
      }

      result =
        Multi.new()
        |> Multi.run(:unit, fn _, _ -> Units.insert_unit(params) end)
        |> Multi.run(:substract_currencies, fn _, _ ->
          Currencies.substract_currencies(user_id, box.cost)
        end)
        |> Transaction.run()

      case result do
        {:error, reason} ->
          {:error, reason}

        {:error, _, _, _} ->
          {:error, :transaction}

        {:ok, %{unit: unit}} ->
          {:ok, user} = Users.get_user(user_id)
          {:ok,
           %{
             unit: unit |> Repo.preload([:items, :character]),
             user: user
           }}
      end
    else
      {:user_exists, false} -> {:error, :user_not_found}
      {:get_box, {:error, :not_found}} -> {:error, :box_not_found}
      {:can_afford, false} -> {:error, :cant_afford}
      {:pull, {:error, :no_character_found}} -> {:error, :no_character_found}
    end
  end
end
