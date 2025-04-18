defmodule Configurator.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias Configurator.Repo
  alias Configurator.Accounts.User
  alias Configurator.Accounts.UserToken

  @doc """
  Finds a user by its email if it exists. Otherwise creates a new one.

  ## Examples

      iex> find_or_create_user("foo@example.com")
      {:ok, %User{}}

      iex> find_or_create_user("foo@example.com")
      {:error, changeset}

  """
  def find_or_create_user(email) do
    case Repo.get_by(User, email: email) do
      nil -> create_user(email)
      user -> {:ok, user}
    end
  end

  @doc """
  Creates a user by its email.

  ## Examples

      iex> create_user("foo@example.com")
      {:ok, %User{}}

      iex> create_user("foo@example.com")
      {:error, changeset}

  """
  def create_user(email) do
    %User{}
    |> User.changeset(%{email: email})
    |> Repo.insert()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end
end
