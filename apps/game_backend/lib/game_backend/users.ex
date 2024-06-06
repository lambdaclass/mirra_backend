defmodule GameBackend.Users do
  @moduledoc """
  The Users module defines utilites for interacting with Users, that are common across all games.

  Operations that can be done to a User are:
  - Create
  - Give rewards (units, items, currency, experience)

  For now, users consist of only a username. No authentication of any sort has been implemented.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias GameBackend.CurseOfMirra.Users, as: CurseUsers
  alias GameBackend.Matches.ArenaMatchResult
  alias GameBackend.Quests.UserQuest
  alias GameBackend.Repo
  alias GameBackend.Transaction
  alias GameBackend.Users.{Currencies, DungeonSettlementLevel, GoogleUser, KalineTreeLevel, User, Unlock, Upgrade}

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
      from(user_quest in UserQuest,
        join: q in assoc(user_quest, :quest),
        where:
          user_quest.inserted_at > ^start_of_date and user_quest.inserted_at < ^end_of_date and
            is_nil(user_quest.completed_at) and
            user_quest.status == ^"available" and q.type == "daily",
        preload: [:quest]
      )

    q =
      from(u in GoogleUser,
        where: u.id in ^ids,
        preload: [
          arena_match_results: ^arena_match_result_subquery,
          user: [
            currencies: :currency,
            user_quests: ^daily_quest_subquery
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
    GoogleUser.changeset(%GoogleUser{}, %{
      email: email,
      user: CurseUsers.create_user_params()
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
  Inserts a KalineTreeLevel into the database.
  """
  def insert_kaline_tree_level(attrs) do
    %KalineTreeLevel{}
    |> KalineTreeLevel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a KalineTreeLevel in the database.
  """
  def update_kaline_tree_level(kaline_tree_level, attrs) do
    kaline_tree_level
    |> KalineTreeLevel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Inserts all KalineTreeLevels into the database. If another one already exists with the same number, it updates it instead.
  """
  def upsert_kaline_tree_levels(attrs_list) do
    Enum.reduce(attrs_list, Ecto.Multi.new(), fn attrs, multi ->
      Multi.run(multi, attrs.level, fn _, _ ->
        upsert_kaline_tree_level(attrs)
      end)
    end)
    |> Repo.transaction()
  end

  defp upsert_kaline_tree_level(attrs) do
    case get_kaline_tree_level(attrs.level) do
      nil -> insert_kaline_tree_level(attrs)
      kaline_tree_level -> update_kaline_tree_level(kaline_tree_level, attrs)
    end
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
    Repo.get_by(DungeonSettlementLevel, level: level_number) |> Repo.preload(:afk_reward_rates)
  end

  @doc """
  Inserts a DungeonSettlementLevel into the database.
  """
  def insert_dungeon_settlement_level(attrs) do
    %DungeonSettlementLevel{}
    |> DungeonSettlementLevel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a DungeonSettlementLevel in the database.
  """
  def update_dungeon_settlement_level(dungeon_settlement_level, attrs) do
    dungeon_settlement_level
    |> DungeonSettlementLevel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Inserts all DungeonSettlementLevels into the database. If another one already exists with the same number, it updates it instead.
  """
  def upsert_dungeon_settlement_levels(attrs_list) do
    Enum.reduce(attrs_list, Ecto.Multi.new(), fn attrs, multi ->
      # Cannot use Multi.insert because of the embeds_many
      Multi.run(multi, attrs.level, fn _, _ ->
        upsert_dungeon_settlement_level(attrs)
      end)
    end)
    |> Repo.transaction()
  end

  @doc """
  Inserts a DungeonSettlementLevel into the database. If another one already exists with the same number, it updates it instead.
  """
  def upsert_dungeon_settlement_level(attrs) do
    case get_dungeon_settlement_level(attrs.level) do
      nil -> insert_dungeon_settlement_level(attrs)
      dungeon_settlement_level -> update_dungeon_settlement_level(dungeon_settlement_level, attrs)
    end
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
  def update_user_kaline_tree_level(user, params),
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
    result =
      Multi.new()
      |> Multi.run(:user, fn _, _ -> increment_tree_level(user_id) end)
      |> Multi.run(:user_currency, fn _, _ ->
        Currencies.substract_currencies(user_id, level_up_costs)
      end)
      |> Repo.transaction()

    case result do
      {:ok, _} ->
        get_user(user_id)

      {:error, _, reason, _} ->
        {:error, reason}
    end

    get_user(user_id)
  end

  defp increment_tree_level(user_id) do
    with {:user, {:ok, user}} <- {:user, get_user(user_id)},
         {:kaline_tree_level, {:ok, next_level}} <-
           {:kaline_tree_level, get_kaline_tree_level(user.kaline_tree_level.level + 1)} do
      user
      |> User.changeset(%{kaline_tree_level_id: next_level.id})
      |> Repo.update()
    else
      {:user, {:error, :not_found}} -> {:error, :user_not_found}
      {:kaline_tree_level, nil} -> {:error, :kaline_tree_max_level_reached}
    end
  end

  @doc """
  Level up the Dungeon Settlement of a user.

  Returns the updated user if the operation was successful.
  """
  def level_up_dungeon_settlement(user_id, level_up_costs) do
    result =
      Multi.new()
      |> Multi.run(:user, fn _, _ -> increment_settlement_level(user_id) end)
      |> Multi.run(:user_currency, fn _, _ ->
        Currencies.substract_currencies(user_id, level_up_costs)
      end)
      |> Repo.transaction()

    case result do
      {:error, reason} -> {:error, reason}
      {:error, _, _, _} -> {:error, :transaction}
      {:ok, _} -> get_user(user_id)
    end
  end

  defp increment_settlement_level(user_id) do
    case get_user(user_id) do
      {:ok, user} ->
        case get_dungeon_settlement_level(user.dungeon_settlement_level.level + 1) do
          nil ->
            {:error, :dungeon_settlement_level_not_found}

          next_level ->
            user
            |> User.changeset(%{dungeon_settlement_level_id: next_level.id})
            |> Repo.update()
        end

      error ->
        error
    end
  end

  defp preload(user),
    do:
      Repo.preload(
        user,
        unlocks: [upgrade: [:buffs, cost: :currency]],
        kaline_tree_level: [afk_reward_rates: :currency],
        dungeon_settlement_level: [afk_reward_rates: :currency, level_up_costs: :currency],
        super_campaign_progresses: :level,
        items: :template,
        units: [:character, :items],
        currencies: :currency
      )

  @doc """
  Get the upgrade with the given id.

  ## Examples

      iex> get_upgrade(upgrade_id)
      {:ok, %Upgrade{id: ^upgrade_id}}
  """
  def get_upgrade(id) do
    case Repo.get(Upgrade, id) do
      nil -> {:error, :not_found}
      upgrade -> {:ok, upgrade}
    end
  end

  @doc """
  Get the upgrade with the given name.

  ## Examples

      iex> get_upgrade_by_name("upgrade_name")
      {:ok, %Upgrade{name: "upgrade_name"}}
  """
  def get_upgrade_by_name(name) do
    case Repo.get_by(Upgrade, name: name) |> Repo.preload(cost: :currency) do
      nil -> {:error, :not_found}
      upgrade -> {:ok, upgrade}
    end
  end

  def user_has_unlock?(user_id, unlock_name) do
    Repo.exists?(from(u in Unlock, where: u.user_id == ^user_id and u.name == ^unlock_name))
  end

  @doc """
  Purchase an upgrade for a user. Adds it to the user's unlocks and substracts the cost from the user's currencies.
  """
  def purchase_upgrade(user_id, upgrade_id, type) do
    with {:user, true} <- {:user, exists?(user_id)},
         {:upgrade, {:ok, upgrade}} <- {:upgrade, get_upgrade(upgrade_id)},
         {:upgrade_owned, false} <- {:upgrade_owned, user_has_unlock?(user_id, upgrade.name)},
         # TODO: Check the upgrade can be bought (unlock requirements) [#CHOM-471]
         {:can_afford, true} <- {:can_afford, Currencies.can_afford(user_id, upgrade.cost)} do
      Multi.new()
      |> Multi.run(:upgrade, fn _, _ ->
        insert_unlock(%{user_id: user_id, upgrade_id: upgrade_id, name: upgrade.name, type: type})
      end)
      |> Multi.run(:substract_currencies, fn _, _ ->
        Currencies.substract_currencies(user_id, upgrade.cost)
      end)
      |> Transaction.run()
      |> case do
        {:ok, _} -> {:ok, get_user(user_id)}
        _ -> {:error, :unknown_error}
      end
    else
      {:user, false} -> {:error, :user_not_found}
      {:upgrade, _} -> {:error, :upgrade_not_found}
      {:upgrade_owned, true} -> {:error, :upgrade_already_owned}
      {:can_afford, false} -> {:error, :cant_afford}
    end
  end

  @doc """
  Insert an Unlock.
  """
  def insert_unlock(attrs) do
    %Unlock{}
    |> Unlock.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get all User's unlocks with a specific type.

  ## Examples

      iex> get_unlocks_with_type("user_id", "type")
      [%Unlock{}]
  """
  def get_unlocks_with_type(user_id, type) do
    Repo.all(from(u in Unlock, where: u.user_id == ^user_id and u.type == ^type, preload: [upgrade: :buffs]))
  end
end
