defmodule Champions.Gacha do
  @moduledoc """
  Gacha logic for Champions of Mirra.
  """

  alias GameBackend.Gacha
  alias GameBackend.Transaction
  alias GameBackend.Users
  alias GameBackend.Users.Currencies
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
  def pull(user_id, box_id) do
    with {:user_exists, true} <- {:user_exists, Users.exists?(user_id)},
         {:get_box, {:ok, box}} <- {:get_box, Gacha.get_box(box_id)},
         {:can_afford, true} <-
           {:can_afford, Currencies.can_afford(user_id, box.cost)} do
      result =
        Multi.new()
        |> Multi.run(:unit, fn _, _ -> Gacha.pull(user_id, box) end)
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
          {:ok, %{unit: unit, user: Users.get_user(user_id)}}
      end
    else
      {:user_exists, false} -> {:error, :user_not_found}
      {:get_box, {:error, :not_found}} -> {:error, :box_not_found}
      {:can_afford, false} -> {:error, :cant_afford}
    end
  end
end
