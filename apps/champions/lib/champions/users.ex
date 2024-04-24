defmodule Champions.Users do
  @moduledoc """
  Users logic for Champions Of Mirra.
  """

  alias GameBackend.Users.Currencies.CurrencyCost
  alias Champions.Users
  alias Champions.Utils
  alias Ecto.Changeset
  alias Ecto.Multi
  alias GameBackend.Items
  alias GameBackend.Transaction
  alias GameBackend.Users.Currencies
  alias GameBackend.Users
  alias GameBackend.Users.Currencies
  alias GameBackend.Units
  alias GameBackend.Units.Characters

  @max_afk_reward_seconds 12 * 60 * 60

  @doc """
  Registers a user. Doesn't handle authentication, users only consist of a unique username for now.

  Sample data is filled to the user for testing purposes.
  """
  def register(username) do
    kaline_tree_level = GameBackend.Users.get_kaline_tree_level(1)

    case Users.register_user(%{
           username: username,
           game_id: Utils.game_id(),
           level: 1,
           experience: 0,
           kaline_tree_level_id: kaline_tree_level.id
         }) do
      {:ok, user} ->
        # For testing purposes, we assign some things to our user.
        add_sample_units(user)
        add_sample_items(user)
        add_sample_currencies(user)
        add_super_campaign_progresses(user)

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
    Users.get_user(user_id)
  end

  @doc """
  Get a user's id by their username.

  Returns `{:error, :not_found}` if no user is found.
  """
  def get_user_by_username(username) do
    Users.get_user_by_username(username)
  end

  defp add_sample_units(user) do
    characters = Characters.get_characters_by_quality(Champions.Units.get_quality(:epic))

    Enum.each(1..6, fn index ->
      Units.insert_unit(%{
        character_id: Enum.random(characters).id,
        user_id: user.id,
        level: Enum.random(1..5),
        rank: Champions.Units.get_rank(:star5),
        tier: 1,
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
    Currencies.add_currency(user.id, Currencies.get_currency_by_name!("Summon Scrolls").id, 100)
    Currencies.add_currency(user.id, Currencies.get_currency_by_name!("Fertilizer").id, 100)
  end

  defp add_super_campaign_progresses(user) do
    {:ok, campaigns} = GameBackend.Campaigns.get_campaigns()
    campaigns = Enum.group_by(campaigns, & &1.super_campaign_id)

    # Add SuperCampaignProgress for each SuperCampaign
    Enum.each(campaigns, fn {super_campaign_id, [first_campaign | _campaigns]} ->
      GameBackend.Campaigns.insert_super_campaign_progress(%{
        game_id: Utils.game_id(),
        user_id: user.id,
        super_campaign_id: super_campaign_id,
        level_id: first_campaign.levels |> Enum.sort_by(& &1.level_number) |> hd() |> Map.get(:id)
      })
    end)
  end

  @doc """
  Adds the given experience to a user. If the user were to have enough resulting experience to level up,
  it is performed automatically.
  """
  def add_experience(user_id, experience) do
    case get_user(user_id) do
      {:ok, user} ->
        new_experience = user.experience + experience

        {new_level, new_experience} = process_level_ups(user.level, new_experience)

        Users.update_experience(user, %{level: new_level, experience: new_experience})

      error ->
        error
    end
  end

  defp process_level_ups(level, experience) do
    experience_to_next_level = calculate_experience_to_next_level(level)

    if experience_to_next_level <= experience,
      do: process_level_ups(level + 1, experience - experience_to_next_level),
      else: {level, experience}
  end

  @doc """
  Calculate how much experience a user with the given level will need to level up.
  """
  def calculate_experience_to_next_level(level) do
    Math.pow(100, 1 + level / 10) |> ceil()
  end

  @doc """
  Get a user's available AFK rewards, according to their AFK reward rates and the time since their last claim.
  If more than 12 hours have passed since the last claim, the user will have accumulated the maximum amount of rewards.
  """
  def get_afk_rewards(user_id) do
    case Users.get_user(user_id) do
      {:ok, user} ->
        user.afk_reward_rates
        |> Enum.map(fn reward_rate ->
          currency = Currencies.get_currency(reward_rate.currency_id)
          amount = calculate_afk_rewards(user, reward_rate)
          %{currency: currency, amount: amount}
        end)

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  defp calculate_afk_rewards(user, afk_reward_rate) do
    last_claim = user.last_afk_reward_claim
    now = DateTime.utc_now()

    # Cap the amount of rewards to the maximum amount of rewards that can be accumulated in 12 hours.
    seconds_since_last_claim = DateTime.diff(now, last_claim, :second)
    (afk_reward_rate.rate * min(seconds_since_last_claim, @max_afk_reward_seconds)) |> round()
  end

  @doc """
  Claim a user's AFK rewards, and reset their last AFK reward claim time.
  """
  def claim_afk_rewards(user_id) do
    afk_rewards = get_afk_rewards(user_id)

    Multi.new()
    |> Multi.run(:add_currencies, fn _, _ ->
      results =
        Enum.map(afk_rewards, fn afk_reward ->
          Currencies.add_currency(user_id, afk_reward.currency.id, trunc(afk_reward.amount))
        end)

      if Enum.all?(results, fn {result, _} -> result == :ok end) do
        {:ok, Enum.map(results, fn {_ok, currency} -> currency end)}
      else
        {:error, "failed"}
      end
    end)
    |> Multi.run(:reset_afk_claim, fn _, _ ->
      Users.reset_afk_rewards_claim(user_id)
    end)
    |> Transaction.run()
    |> case do
      {:ok, result} -> {:ok, result.reset_afk_claim}
      {:error, _, reason, _} -> {:error, reason}
    end
  end

  @doc """
  Level up the Kaline Tree of a user.
  """
  def level_up_kaline_tree(user_id) do
    with {:user, {:ok, user}} <- {:user, Users.get_user(user_id)},
         level_up_costs = calculate_costs_to_level_up_kaline_tree(user),
         {:can_afford, true} <-
           {:can_afford,
            Enum.all?(level_up_costs, fn %CurrencyCost{currency_id: level_up_currency_id, amount: level_up_cost} ->
              Currencies.can_afford(
                user_id,
                level_up_currency_id,
                level_up_cost
              )
            end)} do
      Users.level_up_kaline_tree(user_id, level_up_costs)
    else
      {:can_afford, false} -> {:error, :cant_afford}
    end
  end

  defp calculate_costs_to_level_up_kaline_tree(user),
    do: [
      %CurrencyCost{
        currency_id: Currencies.get_currency_by_name!("Fertilizer").id,
        amount: user.kaline_tree_level.fertilizer_level_up_cost
      },
      %CurrencyCost{
        currency_id: Currencies.get_currency_by_name!("Gold").id,
        amount: user.kaline_tree_level.gold_level_up_cost
      }
    ]
end
