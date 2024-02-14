defmodule GameBackend.Users do
  @moduledoc """
  The Users module defines utilites for interacting with Users, that are common across all games. Also defines the data structures themselves. Operations that can be done to a User are:
  - Create

  For now, users consist of only a username. No authentication of any sort has been implemented.
  """

  import Ecto.Query, warn: false

  alias GameBackend.Campaigns.Level
  alias GameBackend.Repo
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

  Returns nil if no user is found.

  ## Examples

      iex> get_user("51646f3a-d9e9-4ce6-8341-c90b8cad3bdf")
      %User{}

      iex> get_user("9483ae81-f3e8-4050-acea-13940d47d8ed")
      nil
  """
  def get_user(id), do: Repo.get(User, id) |> preload()

  @doc """
  Gets a user by their username.

  Returns nil if no user is found.

  ## Examples

      iex> get_user_by_username("some_user")
      %User{}

      iex> get_user_by_username("non_existing_user")
      nil
  """
  def get_user_by_username(username), do: Repo.get_by(User, username: username) |> preload()

  def advance_level(user_id, campaign_id) do
    # Increment user's level. If it was the last level in the campaign, increment the campaign number and set level number to 1.
    user = Repo.get(User, user_id)

    campaign_levels_amount =
      Repo.all(from(l in Level, where: l.campaign == ^user.current_level)) |> length()

    attrs =
      if user.current_level < campaign_levels_amount do
        %{current_level: user.current_level + 1}
      else
        %{current_level: 1, current_campaign: user.current_campaign + 1}
      end

    user
    |> User.changeset(attrs)
    |> Repo.update!()
  end

  defp preload(user),
    do: Repo.preload(user, items: :template, units: [:character, :items], currencies: :currency)
end
