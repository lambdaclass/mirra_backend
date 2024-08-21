defmodule GameBackend.Users do
  @moduledoc """
  The Users module defines utilites for interacting with Users, that are common across all games.

  Operations that can be done to a User are:
  - Create
  - Give rewards (units, items, currency, experience)

  For now, users consist of only a username. No authentication of any sort has been implemented.
  """

  import Ecto.Query, warn: false
  alias GameBackend.CurseOfMirra.Quests
  alias Ecto.Multi
  alias GameBackend.CurseOfMirra.Users, as: CurseUsers
  alias GameBackend.Matches.ArenaMatchResult
  alias GameBackend.Quests.UserQuest
  alias GameBackend.Repo
  alias GameBackend.Transaction
  alias GameBackend.Users.{Currencies, DungeonSettlementLevel, GoogleUser, KalineTreeLevel, User, Unlock, Upgrade}
  alias GameBackend.Units.Unit

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
  Gets a single user with the same game_id.
  Returns {:ok, User}.
  Returns {:error, :not_found} if no user is found.

  ## Examples

      iex> get_user_by_id_and_game_id("51646f3a-d9e9-4ce6-8341-c90b8cad3bdf", 1)
      {:ok, %User{}}

      iex> get_user_by_id_and_game_id("9483ae81-f3e8-4050-acea-13940d47d8ed", 4)
      {:error, :not_found}
  """
  def get_user_by_id_and_game_id(id, game_id) do
    quest_refresh_at =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(1, :day)
      |> NaiveDateTime.beginning_of_day()
      |> NaiveDateTime.to_iso8601()

    q =
      from(u in User,
        as: :user,
        where: u.id == ^id and u.game_id == ^game_id,
        preload: [
          [units: [:character, :items]],
          [currencies: [:currency]]
        ],
        select: %{u | quest_refresh_at: ^quest_refresh_at}
      )
      |> quests_preloads()
      |> arena_match_results_preloads()
      |> add_user_stats_to_user_query()

    user =
      Repo.one(q)
      |> add_quest_progress_and_goal()

    if user, do: {:ok, user}, else: {:error, :not_found}
  end

  defp add_user_stats_to_user_query(base_query) do
    kills_subquery =
      from(amr in GameBackend.Matches.ArenaMatchResult,
        select: count(amr.kills),
        where: parent_as(:user).id == amr.user_id
      )

    won_matches_subquery =
      from(amr in GameBackend.Matches.ArenaMatchResult,
        select: count(),
        where: parent_as(:user).id == amr.user_id and amr.result == ^"win"
      )

    most_played_character_subquery =
      from(amr in GameBackend.Matches.ArenaMatchResult,
        select: amr.character,
        group_by: amr.character,
        order_by: [desc: count(amr.character)],
        where: parent_as(:user).id == amr.user_id,
        limit: 1
      )

    prestige_subquery =
      from(unit in Unit,
        where: parent_as(:user).id == unit.user_id,
        select: sum(unit.prestige)
      )

    from(u in base_query,
      select_merge: %{
        most_played_character: subquery(most_played_character_subquery),
        total_kills: subquery(kills_subquery),
        won_matches: subquery(won_matches_subquery),
        prestige: subquery(prestige_subquery)
      }
    )
  end

  @doc """
  Get a list of User based on their id with the necessary preloads
  to process quests.

  - user_quests: status equals "available" and completed_at is nil
    - quest where the type is daily and it was inserted the same day of the query run
    - quest where the type is weekly and it didn't pass more than 6 days from the last sunday since they were inserted
  - arena_match_results: it didn't pass more than 6 days from the last sunday since they were inserted

  ## Examples

      iex> list_users_with_quests_and_results(["51646f3a-d9e9-4ce6-8341-c90b8cad3bdf"])
      [%User{}]
  """
  def list_users_with_quests_and_results(ids, repo \\ Repo) do
    q =
      from(u in User,
        as: :user,
        where: u.id in ^ids,
        preload: [
          currencies: :currency,
          units: :character
        ]
      )
      |> quests_preloads()
      |> arena_match_results_preloads()
      |> add_user_stats_to_user_query()

    repo.all(q)
  end

  defp quests_preloads(base_query) do
    naive_today = NaiveDateTime.utc_now()
    start_of_date = NaiveDateTime.beginning_of_day(naive_today)
    end_of_date = NaiveDateTime.end_of_day(naive_today)

    start_of_week = Date.beginning_of_week(NaiveDateTime.to_date(naive_today), :sunday)
    end_of_week = Date.add(start_of_week, 6)
    {:ok, start_of_week_naive} = NaiveDateTime.new(start_of_week, ~T[00:00:00])
    {:ok, end_of_week_naive} = NaiveDateTime.new(end_of_week, ~T[23:59:59])

    quests_subquery =
      from(user_quest in UserQuest,
        as: :user_quest,
        join: quest in assoc(user_quest, :quest),
        as: :quest,
        where:
          (quest.type in ^["daily", "meta"] and user_quest.inserted_at > ^start_of_date and
             user_quest.inserted_at < ^end_of_date) or
            (quest.type == ^"weekly" and user_quest.inserted_at > ^start_of_week_naive and
               user_quest.inserted_at < ^end_of_week_naive),
        preload: [:quest]
      )

    from(u in base_query,
      preload: [
        user_quests: ^quests_subquery
      ]
    )
  end

  defp arena_match_results_preloads(base_query) do
    date_today = Date.utc_today()
    start_of_week = Date.beginning_of_week(date_today, :sunday)
    end_of_week = Date.add(start_of_week, 6)
    {:ok, start_of_week_naive} = NaiveDateTime.new(start_of_week, ~T[00:00:00])
    {:ok, end_of_week_naive} = NaiveDateTime.new(end_of_week, ~T[23:59:59])

    arena_match_result_subquery =
      from(amr in ArenaMatchResult,
        where: amr.inserted_at > ^start_of_week_naive and amr.inserted_at < ^end_of_week_naive
      )

    from(u in base_query,
      preload: [arena_match_results: ^arena_match_result_subquery]
    )
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
    q =
      from(gu in GoogleUser,
        where: gu.email == ^email,
        preload: [:user]
      )

    case Repo.one(q) do
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
  Gets a DungeonSettlementLevel by its id.
  """
  def get_dungeon_settlement_level(dungeon_settlement_level_id) do
    Repo.get(DungeonSettlementLevel, dungeon_settlement_level_id)
  end

  @doc """
  Gets a DungeonSettlementLevel by its number.

  Returns {:error, :not_found} if no level is found.

  ## Examples

      iex> get_dungeon_settlement_level_by_number(1)
      %DungeonSettlementLevel{}

      iex> get_dungeon_settlement_level_by_number(-1)
      nil
  """
  def get_dungeon_settlement_level_by_number(level_number) do
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
    case get_dungeon_settlement_level_by_number(attrs.level) do
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
    result =
      Multi.new()
      |> Multi.run(:user, fn _, _ -> increment_settlement_level(user_id) end)
      |> Multi.run(:user_currency, fn _, _ ->
        Currencies.substract_currencies(user_id, level_up_costs)
      end)
      |> Multi.run(:supply_cap, fn _, %{user: user} ->
        dungeon_settlement_level = Repo.get(DungeonSettlementLevel, user.dungeon_settlement_level_id)

        Currencies.update_user_currency_cap(
          user.id,
          {"Supplies", user.game_id},
          dungeon_settlement_level.supply_cap
        )
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
        case get_dungeon_settlement_level_by_number(user.dungeon_settlement_level.level + 1) do
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

  @doc """
  Returns if a unit exist for the user id using the name field from the character association.

  ## Examples

      iex> user_has_unit_with_character_name(user_id, "muflus")
      true
  """
  def user_has_unit_with_character_name(user_id, character_name) do
    q =
      from(u in GameBackend.Units.Unit,
        join: c in assoc(u, :character),
        where: u.user_id == ^user_id and c.name == ^character_name
      )

    Repo.exists?(q)
  end

  def get_users_sorted_by_total_unit_prestige() do
    q =
      from(user in User,
        join: unit in Unit,
        on: user.id == unit.user_id,
        select: %{user_id: user.id, username: user.username, prestige: sum(unit.prestige)},
        group_by: user.id,
        order_by: [desc: sum(unit.prestige)],
        limit: 100
      )

    Repo.all(q)
  end

  defp add_quest_progress_and_goal(%User{} = user) do
    today = Date.utc_today()
    start_of_week = Date.beginning_of_week(today, :sunday)

    updated_quests =
      Enum.map(user.user_quests, fn user_quest ->
        quest_progress =
          Quests.get_user_quest_progress(user_quest, user.arena_match_results, user)

        Map.put(user_quest, :progress, quest_progress)
        |> Map.put(:goal, user_quest.quest.objective["value"])
      end)

    daily_quests_week_progress =
      Enum.map(Date.range(start_of_week, today), fn date ->
        completed_quests_amount =
          Enum.count(user.user_quests, fn user_quest ->
            user_quest.status == "completed" && Date.diff(date, NaiveDateTime.to_date(user_quest.inserted_at)) == 0
          end)

        %{
          completed_quests_amount: completed_quests_amount,
          # We'll hardcore this value for the time being since we don't have any spec for the specific amount, that's
          # described in the meta quest but we could have more than one in the future
          target_quests_amount: 6,
          date: date
        }
      end)

    user
    |> Map.put(:user_quests, updated_quests)
    |> Map.put(:daily_quests_week_progress, daily_quests_week_progress)
  end

  defp add_quest_progress_and_goal(_), do: nil

  def insert_curse_user_and_insert_daily_quests() do
    curse_id = GameBackend.Utils.get_game_id(:curse_of_mirra)

    Multi.new()
    |> Multi.run(:insert_user, fn _, _ ->
      CurseUsers.create_user_params()
      |> register_user()
    end)
    |> Multi.run(:generate_quests, fn
      _, %{insert_user: user} ->
        case generate_daily_quests_for_user(user) do
          {:error, changeset} ->
            {:error, changeset}

          _ ->
            {:ok, :quests_generated}
        end
    end)
    |> Multi.run(:user, fn _, %{insert_user: user} ->
      get_user_by_id_and_game_id(user.id, curse_id)
    end)
    |> Repo.transaction()
  end

  def maybe_generate_daily_quests_for_curse_user(user_id) do
    Multi.new()
    |> Multi.run(:get_user, fn _, _ -> get_user(user_id) end)
    |> Multi.run(:maybe_generate_quests, fn
      _, %{get_user: user} ->
        today = Date.utc_today()

        should_generate_quests? =
          user.last_daily_quest_generation_at &&
            Date.compare(NaiveDateTime.to_date(user.last_daily_quest_generation_at), today) == :lt

        if should_generate_quests? do
          quest_insertion_result = generate_daily_quests_for_user(user)

          user_update =
            user
            |> GameBackend.Users.User.changeset(%{last_daily_quest_generation_at: NaiveDateTime.utc_now()})
            |> Repo.update()

          case {quest_insertion_result, user_update} do
            {{:ok, _}, {:ok, user}} ->
              {:ok, user}

            {{:error, changeset}, _user_update} ->
              {:error, changeset}

            {_, {:error, user_changeset}} ->
              {:error, user_changeset}
          end
        else
          {:ok, :not_needed}
        end
    end)
    |> Repo.transaction()
  end

  defp generate_daily_quests_for_user(user) do
    available_quests =
      Quests.get_user_missing_quests_by_type(user.id, "daily")
      |> Enum.shuffle()

    meta_quest_params =
      Quests.get_user_missing_quests_by_type(user.id, "meta")
      |> Enum.shuffle()
      |> hd()

    attrs = %{
      user_id: user.id,
      quest_id: meta_quest_params.id,
      status: "available",
      activated_at: NaiveDateTime.utc_now()
    }

    changeset = UserQuest.changeset(%UserQuest{}, attrs)

    meta_quest_result = Repo.insert(changeset)

    {active_quests_params, remaining_quests} = Enum.split(available_quests, 3)

    {inactive_quests_params, _remaining_quests} = Enum.split(remaining_quests, 3)

    active_quests =
      Enum.map(active_quests_params, fn
        quest_params ->
          attrs = %{
            user_id: user.id,
            quest_id: quest_params.id,
            status: "available",
            activated_at: NaiveDateTime.utc_now()
          }

          changeset = UserQuest.changeset(%UserQuest{}, attrs)

          Repo.insert(changeset)
      end)

    inactive_quests =
      Enum.map(inactive_quests_params, fn
        quest_params ->
          attrs = %{
            user_id: user.id,
            quest_id: quest_params.id,
            status: "available"
          }

          changeset = UserQuest.changeset(%UserQuest{}, attrs)

          Repo.insert(changeset)
      end)

    (active_quests ++ inactive_quests ++ [meta_quest_result])
    |> Enum.find(fn {result, _quest} -> result == :error end)
    |> case do
      nil -> {:ok, :quests_inserted}
      {:error, changeset} -> {:error, changeset}
    end
  end
end
