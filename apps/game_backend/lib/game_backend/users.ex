defmodule GameBackend.Users do
  @moduledoc """
  The Users module defines utilites for interacting with Users, that are common across all games.

  Operations that can be done to a User are:
  - Create
  - Give rewards (units, items, currency, experience)

  For now, users consist of only a username. No authentication of any sort has been implemented.
  """

  import Ecto.Query, warn: false

  alias GameBackend.Quests.DailyQuest
  alias GameBackend.Matches.ArenaMatchResult
  alias GameBackend.Users.DungeonSettlementLevel
  alias GameBackend.Users.KalineTreeLevel
  alias Ecto.Multi
  alias GameBackend.Repo
  alias GameBackend.Users.Currencies
  alias GameBackend.Users.User
  alias GameBackend.Users.GoogleUser
  alias GameBackend.Utils

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
  Returns {:ok, User}.
  Returns {:error, :not_found} if no user is found.

  ## Examples

      iex> get_user("51646f3a-d9e9-4ce6-8341-c90b8cad3bdf")
      {:ok, %User{}}

      iex> get_user("9483ae81-f3e8-4050-acea-13940d47d8ed")
      {:error, :not_found}
  """
  def get_user(id) do
    user = Repo.get(User, id) |> preload()
    if user, do: {:ok, user}, else: {:error, :not_found}
  end

  @doc """
  Get a list of GoogleUser based on their id with the necessary preloads
  to process daily quests.

  ## Examples

      iex> get_google_users_with_todays_daily_quests(["51646f3a-d9e9-4ce6-8341-c90b8cad3bdf"])
      [%GoogleUser{}]
  """
  def get_google_users_with_todays_daily_quests(ids, repo \\ Repo) do
    naive_today = NaiveDateTime.utc_now()
    start_of_date = NaiveDateTime.beginning_of_day(naive_today)
    end_of_date = NaiveDateTime.end_of_day(naive_today)

    arena_match_result_subquery =
      from(amr in ArenaMatchResult,
        where: amr.inserted_at > ^start_of_date and amr.inserted_at < ^end_of_date
      )

    daily_quest_subquery =
      from(dq in DailyQuest,
        where: dq.inserted_at > ^start_of_date and dq.inserted_at < ^end_of_date and not dq.completed,
        preload: [:quest]
      )

    q =
      from(u in GoogleUser,
        where: u.id in ^ids,
        preload: [
          arena_match_results: ^arena_match_result_subquery,
          user: [
            currencies: :currency,
            daily_quests: ^daily_quest_subquery
          ]
        ]
      )

    repo.all(q)
  end

  @doc """
  Gets a single GoogleUser.
  Returns {:ok, GoogleUser}.
  Returns {:error, :not_found} if no user is found.

  ## Examples

      iex> get_user("51646f3a-d9e9-4ce6-8341-c90b8cad3bdf")
      {:ok, %GoogleUser{}}

      iex> get_user("9483ae81-f3e8-4050-acea-13940d47d8ed")
      {:error, :not_found}
  """
  def get_google_user(id) do
    user =
      Repo.get(GoogleUser, id)
      |> Repo.preload([:user])

    if user, do: {:ok, user}, else: {:error, :not_found}
  end

  @doc """
  Updates the given user by given params.
  Returns {:ok, User}.
  Returns {:error, Changeset} if update transaction fails.

  ## Examples

      iex> update_user("51646f3a-d9e9-4ce6-8341-c90b8cad3bdf", %{valid_param: valid_value})
      {:ok, %User{}}

      iex> update_user("9483ae81-f3e8-4050-acea-13940d47d8ed", %{invalid_param: invalid_value})
      {:error, %Changeset{}}
  """
  def update_user(%User{} = user, params) do
    User.changeset(user, params)
    |> Repo.update()
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
  Gets a GoogleUser by their email.
  Creates a GoogleUser if none is found.
  Returns {:error, changeset} if the creation failed.

  ## Examples

      iex> find_or_create_google_user_by_email("some_email")
      {:ok, %GoogleUser{}}

      iex> find_or_create_google_user_by_email("non_existing_email")
      {:ok, %GoogleUser{}}
  """
  def find_or_create_google_user_by_email(email) do
    case Repo.get_by(GoogleUser, email: email) do
      nil -> create_google_user_by_email(email)
      user -> {:ok, user}
    end
  end

  defp create_google_user_by_email(email) do
    # TODO delete the following in a future refactor -> https://github.com/lambdaclass/mirra_backend/issues/557
    level = 1
    experience = 1
    amount_of_users = Repo.aggregate(GameBackend.Users.User, :count)
    username = "User_#{amount_of_users + 1}"
    ##################################################################
    game_id = Utils.get_game_id(:curse_of_mirra)

    GoogleUser.changeset(%GoogleUser{}, %{
      email: email,
      user: %{
        game_id: game_id,
        username: username,
        level: level,
        experience: experience
      }
    })
    |> Repo.insert()
  end

  @doc """
  Gets a KalineTreelevel by its number.

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
  Gets a DungeonSettlementLevel by its number.

  Returns {:error, :not_found} if no level is found.

  ## Examples

      iex> get_dungeon_settlement_level(1)
      %DungeonSettlementLevel{}

      iex> get_dungeon_settlement_level(-1)
      nil
  """
  def get_dungeon_settlement_level(level_number) do
    Repo.get_by(DungeonSettlementLevel, level: level_number)
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

  @doc """
  Updates the Kaline Tree level of a user.
  """
  def update_kaline_tree_level(user, params),
    do:
      user
      |> User.kaline_tree_level_changeset(params)
      |> Repo.update()

  @doc """
  Resets the AFK rewards claim time of a user, setting it to the current time.
  """
  def reset_afk_rewards_claim(user_id, :kaline) do
    {:ok, user} = get_user(user_id)

    user
    |> User.changeset(%{last_kaline_afk_reward_claim: DateTime.utc_now()})
    |> Repo.update()
  end

  def reset_afk_rewards_claim(user_id, :dungeon) do
    {:ok, user} = get_user(user_id)

    user
    |> User.changeset(%{last_dungeon_afk_reward_claim: DateTime.utc_now()})
    |> Repo.update()
  end

  @doc """
  Level up the Kaline Tree of a user.

  Returns the updated user if the operation was successful.
  """
  def level_up_kaline_tree(user_id, level_up_costs) do
    {:ok, _result} =
      Multi.new()
      |> Multi.run(:user, fn _, _ -> increment_tree_level(user_id) end)
      |> Multi.run(:user_currency, fn _, _ ->
        Currencies.substract_currencies(user_id, level_up_costs)
      end)
      |> Repo.transaction()

    get_user(user_id)
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

  @doc """
  Level up the Dungeon Settlement of a user.

  Returns the updated user if the operation was successful.
  """
  def level_up_dungeon_settlement(user_id, level_up_costs) do
    {:ok, _result} =
      Multi.new()
      |> Multi.run(:user, fn _, _ -> increment_settlement_level(user_id) end)
      |> Multi.run(:user_currency, fn _, _ ->
        Currencies.substract_currencies(user_id, level_up_costs)
      end)
      |> Repo.transaction()

    get_user(user_id)
  end

  defp increment_settlement_level(user_id) do
    case get_user(user_id) do
      {:ok, user} ->
        next_level = get_dungeon_settlement_level(user.dungeon_settlement_level.level + 1)

        user
        |> User.changeset(%{dungeon_settlement_level_id: next_level.id})
        |> Repo.update()

      error ->
        error
    end
  end

  defp preload(user),
    do:
      Repo.preload(
        user,
        kaline_tree_level: [afk_reward_rates: :currency],
        dungeon_settlement_level: [afk_reward_rates: :currency, level_up_costs: :currency],
        super_campaign_progresses: :level,
        items: :template,
        units: [:character, :items],
        currencies: :currency
      )
end
