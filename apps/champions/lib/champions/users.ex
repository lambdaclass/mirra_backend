defmodule Champions.Users do
  @moduledoc """
  Users logic for Champions Of Mirra.
  """

  alias Ecto.Changeset
  alias GameBackend.Users.Currencies
  alias GameBackend.Users
  alias GameBackend.Units
  alias GameBackend.Items

  @game_id 2

  @doc """
  Registers a user. Doesn't handle authentication, users only consist of a unique username for now.

  Sample data is filled to the user for testing purposes.
  """
  def register(username) do
    case Users.register_user(%{username: username, game_id: @game_id}) do
      {:ok, user} ->
        # For testing purposes, we assign some things to our user.
        add_sample_units(user)
        add_sample_items(user)
        add_sample_currencies(user)

        Users.get_user(user.id)

      {:error, changeset} ->
        [[first_error | _other_errors] | _other_fields_errors] =
          Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end) |> Map.values()

        case first_error do
          "has already been taken" -> {:error, :username_taken}
          "can't be blank" -> {:error, :missing_fields}
          _ -> {:error, :unkown}
        end
    end
  end

  @doc """
  Get a user by id.

  Returns `{:error, :not_found}` if no user is found.
  """
  def get_user(user_id) do
    case Users.get_user(user_id) do
      nil -> {:error, :not_found}
      user -> user
    end
  end

  @doc """
  Get a user's id by their username.

  Returns `{:error, :not_found}` if no user is found.
  """
  def get_user_by_username(username) do
    case Users.get_user_by_username(username) do
      nil -> {:error, :not_found}
      user -> user
    end
  end

  @doc """
  Gets how much a user has of a given currency by its name.
  """
  def get_amount_of_currency_by_name!(user_id, currency_name),
    do:
      user_id
      |> Currencies.get_amount_of_currency(Currencies.get_currency_by_name!(currency_name).id)

  @doc """
  Add amount of currency to user by its name.
  """
  def add_currency_by_name!(user_id, currency_name, amount),
    do:
      user_id
      |> Currencies.add_currency(Currencies.get_currency_by_name!(currency_name).id, amount)

  defp add_sample_units(user) do
    characters = Units.all_characters()

    Enum.each(1..5, fn index ->
      Units.insert_unit(%{
        character_id: Enum.random(characters).id,
        user_id: user.id,
        unit_level: Enum.random(1..5),
        tier: 1,
        rank: 1,
        selected: true,
        slot: index
      })
    end)
  end

  defp add_sample_items(user) do
    Items.get_item_templates()
    |> Enum.each(fn template ->
      Items.insert_item(%{user_id: user.id, template_id: template.id, level: Enum.random(1..5)})
    end)
  end

  defp add_sample_currencies(user) do
    Currencies.add_currency(user.id, Currencies.get_currency_by_name!("Gold").id, 100)
    Currencies.add_currency(user.id, Currencies.get_currency_by_name!("Gems").id, 500)
  end

  def get_units(user_id) do
    Users.get_units(user_id)
  end
end
