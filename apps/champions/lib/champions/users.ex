defmodule Champions.Users do
  @moduledoc """
  Users logic for Champions Of Mirra.
  """

  alias Ecto.Changeset
  alias GameBackend.Users.Currencies
  alias GameBackend.Users
  alias GameBackend.Units
  alias GameBackend.Items
  alias GameBackend.Rewards

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
        add_campaigns_progression(user)
        add_afk_reward_rates(user)

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

  defp add_sample_units(user) do
    characters = Units.all_characters()

    Enum.each(0..4, fn index ->
      Units.insert_unit(%{
        character_id: Enum.random(characters).id,
        user_id: user.id,
        unit_level: Enum.random(1..5),
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
  end

  defp add_campaigns_progression(user) do
    campaigns = GameBackend.Campaigns.get_campaigns()

    Enum.each(campaigns, fn campaign ->
      GameBackend.Campaigns.insert_campaign_progression(%{
        game_id: @game_id,
        user_id: user.id,
        campaign_id: campaign.id,
        level_id: campaign.levels |> hd() |> Map.get(:id)
      })
    end)
  end

  defp add_afk_reward_rates(user) do
    ["Gold", "Gems", "Summon Scrolls"]
    |> Enum.each(fn currency_name ->
      Rewards.insert_afk_reward_rate(%{
        user_id: user.id,
        currency_id: Currencies.get_currency_by_name!(currency_name).id,
        rate: 0
      })
    end)
  end

  @doc """
  Adds the given experience to a user. If the user were to have enough resulting experience to level up,
  it is performed automatically.
  """
  def add_experience(user_id, experience) do
    user = get_user(user_id)
    new_experience = user.experience + experience

    # Level up

    {new_level, new_experience} = process_level_ups(user.level, new_experience)

    Users.update_experience(user, %{level: new_level, experience: new_experience})
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
    user = Users.get_user(user_id)

    user.afk_reward_rates
    |> Enum.map(fn reward_rate ->
      currency = Currencies.get_currency(reward_rate.currency_id)
      amount = calculate_afk_rewards(user, reward_rate)
      %{currency: currency, amount: amount}
    end)
  end

  defp calculate_afk_rewards(user, afk_reward_rate) do
    last_claim = user.last_afk_reward_claim
    IO.inspect(last_claim, label: "last_claim")
    now = DateTime.utc_now()

    minutes_since_last_claim = DateTime.diff(now, last_claim, :minute)
    hours_since_last_claim = div(minutes_since_last_claim, 60)

    if hours_since_last_claim > 12,
      do: afk_reward_rate.rate * 720,
      else: afk_reward_rate.rate * minutes_since_last_claim
  end

  @doc """
  Claim a user's AFK rewards.
  """
  def claim_afk_rewards(user_id) do
    user = Users.get_user(user_id)

    afk_rewards = get_afk_rewards(user_id)

    Enum.each(afk_rewards, fn {currency, amount} ->
      Currencies.add_currency(user.id, currency.id, amount)
    end)

    Users.reset_afk_rewards_claim(user.id)
  end
end
