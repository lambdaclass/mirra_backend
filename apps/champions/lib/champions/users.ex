defmodule Champions.Users do
  @moduledoc """
  Users logic for Champions Of Mirra.
  """

  alias Champions.Utils
  alias Ecto.Changeset
  alias GameBackend.Users.Currencies
  alias GameBackend.Users
  alias GameBackend.Units
  alias GameBackend.Items

  @doc """
  Registers a user. Doesn't handle authentication, users only consist of a unique username for now.

  Sample data is filled to the user for testing purposes.
  """
  def register(username) do
    case Users.register_user(%{username: username, game_id: Utils.game_id()}) do
      {:ok, user} ->
        # For testing purposes, we assign some things to our user.
        add_sample_units(user)
        add_sample_items(user)
        add_sample_currencies(user)
        add_campaigns_progress(user)

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
    characters = Units.all_characters()

    Enum.each(1..6, fn index ->
      Units.insert_unit(%{
        character_id: Enum.random(characters).id,
        user_id: user.id,
        level: Enum.random(1..5),
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

  defp add_campaigns_progress(user) do
    campaigns = GameBackend.Campaigns.get_campaigns()

    Enum.each(campaigns, fn campaign ->
      if campaign.campaign_number == 1,
        do:
          GameBackend.Campaigns.insert_campaign_progress(%{
            game_id: Utils.game_id(),
            user_id: user.id,
            campaign_id: campaign.id,
            level_id: campaign.levels |> Enum.sort_by(& &1.level_number) |> hd() |> Map.get(:id)
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
end
