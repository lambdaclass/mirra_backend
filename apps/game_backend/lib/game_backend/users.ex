defmodule GameBackend.Users do
  @moduledoc """
  The Users module defines utilites for interacting with Users, that are common across all games.

  Operations that can be done to a User are:
  - Create
  - Give rewards (units, items, currency, experience)

  For now, users consist of only a username. No authentication of any sort has been implemented.
  """

  import Ecto.Query, warn: false

  alias GameBackend.Users.KalineTreeLevel
  alias Ecto.Multi
  alias GameBackend.Repo
  alias GameBackend.Users.Currencies
  alias GameBackend.Users.User

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a single user.

  Returns {:error, :not_found} if no user is found.

  ## Examples

      iex> get_user("51646f3a-d9e9-4ce6-8341-c90b8cad3bdf")
      %User{}

      iex> get_user("9483ae81-f3e8-4050-acea-13940d47d8ed")
      nil
  """
  def get_user(id) do
    user = Repo.get(User, id) |> preload()
    if user, do: {:ok, user}, else: {:error, :not_found}
  end

  @doc """
  Gets a user by their username.

  Returns {:error, :not_found} if no user is found.

  ## Examples

      iex> get_user_by_username("some_user")
      {:ok, %User{}}

      iex> get_user_by_username("non_existing_user")
      {:error, :not_found}
  """
  def get_user_by_username(username) do
    user = Repo.get_by(User, username: username) |> preload()
    if user, do: {:ok, user}, else: {:error, :not_found}
  end

  @doc """
  Gets a Kaline Tree level by its number.

  Returns {:error, :not_found} if no level is found.

  ## Examples

      iex> get_kaline_tree_level(1)
      %KalineTreeLevel{}

      iex> get_kaline_tree_level(-1)
      nil
  """
  def get_kaline_tree_level(level_number) do
    Repo.get_by(KalineTreeLevel, level: level_number)
  end

  @doc """
  Checks whether a user exists with the given id.

  Useful if you want to validate an id while not needing to operate with the user itself.
  """
  def exists?(user_id), do: Repo.exists?(from(u in User, where: u.id == ^user_id))

  def update_experience(user, params),
    do:
      user
      |> User.experience_changeset(params)
      |> Repo.update()

  def update_kaline_tree_level(user, params),
    do:
      user
      |> User.kaline_tree_level_changeset(params)
      |> Repo.update()

  def reset_afk_rewards_claim(user_id) do
    {:ok, user} = get_user(user_id)

    user
    |> User.changeset(%{last_afk_reward_claim: DateTime.utc_now()})
    |> Repo.update()
  end

  def level_up_kaline_tree(user_id, currency_id, level_up_cost) do
    {:ok, result} =
      Multi.new()
      |> Multi.run(:user, fn _, _ -> increment_tree_level(user_id) end)
      |> Multi.run(:user_currency, fn _, _ ->
        Currencies.add_currency(user_id, currency_id, -level_up_cost)
      end)
      |> Repo.transaction()

    {:ok, result.user |> preload()}
  end

  defp increment_tree_level(user_id) do
    case get_user(user_id) do
      {:ok, user} ->
        next_level = get_kaline_tree_level(user.kaline_tree_level.level + 1)

        user
        |> User.changeset(%{kaline_tree_level_id: next_level.id})
        |> Repo.update()

      error ->
        error
    end
  end

  defp preload(user),
    do:
      Repo.preload(
        user,
        [
          :kaline_tree_level,
          afk_reward_rates: :currency,
          super_campaign_progresses: :level,
          items: :template,
          units: [:character, :items],
          currencies: :currency
        ]
      )
end
