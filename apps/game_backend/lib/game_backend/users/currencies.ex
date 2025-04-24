defmodule GameBackend.Users.Currencies do
  @moduledoc """
  The Currencies context.
  """

  import Ecto.Query, warn: false

  alias GameBackend.Users.Currencies.{Currency, CurrencyCost, UserCurrency, UserCurrencyCap}
  alias GameBackend.Repo

  @doc """
  Inserts a currency.

  ## Examples

      iex> insert_currency(%{field: value})
      {:ok, %Currency{}}

      iex> insert_currency(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def insert_currency(attrs) do
    %Currency{}
    |> Currency.changeset(attrs)
    |> Repo.insert()
  end

  def get_currency(currency_id), do: Repo.get(Currency, currency_id)

  @doc """
  Gets a single currency.

  Raises `Ecto.NoResultsError` if the Currency does not exist.

  ## Examples

      iex> get_currency_by_name_and_game!("gold", 1)
      %Currency{}

      iex> get_currency_by_name_and_game!("silver", 1)
      ** (Ecto.NoResultsError)

  """
  def get_currency_by_name_and_game!(name, game_id), do: Repo.get_by!(Currency, name: name, game_id: game_id)

  @doc """
  Gets a single currency.
  Returns {:ok, currency} if query succeeds.
  Returns {:error, :not_found} if the Currency does not exist.

  ## Examples

      iex> get_currency_by_name_and_game("gold", 1)
      {:ok, %Currency{}}

      iex> get_currency_by_name_and_game("silver", 1)
      {:error, :not_found}

  """
  def get_currency_by_name_and_game(name, game_id) do
    case Repo.get_by(Currency, name: name, game_id: game_id) do
      nil -> {:error, :not_found}
      currency -> {:ok, currency}
    end
  end

  @doc """
  Gets how much a user has of a given currency.
  """
  def get_amount_of_currency(user_id, currency_id),
    do:
      Repo.one(
        from(uc in UserCurrency,
          where: uc.user_id == ^user_id and uc.currency_id == ^currency_id,
          select: uc.amount
        )
      ) || 0

  @doc """
  Get a UserCurrency.
  """
  def get_user_currency(user_id, currency_id),
    do:
      Repo.one(
        from(uc in UserCurrency,
          where: uc.user_id == ^user_id and uc.currency_id == ^currency_id
        )
      )

  @doc """
  Returns whether the user can afford the required amounts of the specified currencies.
  """
  def can_afford(user_id, currencies_list) do
    Enum.all?(currencies_list, fn %CurrencyCost{currency_id: currency_id, amount: amount} ->
      can_afford(user_id, currency_id, amount)
    end)
  end

  @doc """
  Returns whether the user can afford the required amount of the specified currency.
  """
  def can_afford(user_id, currency_id, required_amount) do
    user_balance = get_amount_of_currency(user_id, currency_id)
    user_balance >= required_amount
  end

  @doc """
  Gets how much a user has of a given currency by its name.
  """
  def get_amount_of_currency_by_name(user_id, currency_name) do
    Repo.one(
      from(uc in UserCurrency,
        join: currency in assoc(uc, :currency),
        where: uc.user_id == ^user_id and currency.name == ^currency_name,
        select: uc.amount
      )
    ) || 0
  end

  @doc """
  Inserts an UserCurrencyCap.
  """
  def insert_user_currency_cap(attrs) do
    %UserCurrencyCap{}
    |> UserCurrencyCap.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a User's UserCurrencyCap cap for a given currency.

  Currency is identified by a name and a game id.
  """
  def update_user_currency_cap(user_id, {currency_name, game_id}, new_cap) do
    get_user_currency_cap(user_id, get_currency_by_name_and_game!(currency_name, game_id).id)
    |> UserCurrencyCap.update_changeset(%{cap: new_cap})
    |> Repo.update()
  end

  @doc """
  Get an UserCurrencyCap.
  """
  def get_user_currency_cap(user_id, currency_id),
    do: Repo.one(from(uc in UserCurrencyCap, where: uc.user_id == ^user_id and uc.currency_id == ^currency_id))
end
