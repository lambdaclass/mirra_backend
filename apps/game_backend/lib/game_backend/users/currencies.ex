defmodule GameBackend.Users.Currencies do
  @moduledoc """
  The Currencies context.
  """

  import Ecto.Query, warn: false

  alias GameBackend.Users.Currencies.CurrencyCost
  alias GameBackend.Users.Currencies.UserCurrency
  alias GameBackend.Users.Currencies.Currency
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

      iex> get_currency!("gold")
      %Currency{}

      iex> get_currency!("silver")
      ** (Ecto.NoResultsError)

  """
  def get_currency_by_name!(name), do: Repo.get_by!(Currency, name: name)

  @doc """
  Adds (or substracts) the given amount of currency to a user.
  Creates the relational table if it didn't exist previously.
  """
  def add_currency(user_id, currency_id, amount) do
    case get_user_currency(user_id, currency_id) do
      %UserCurrency{} = user_currency ->
        user_currency
        |> UserCurrency.update_changeset(%{
          amount: max(user_currency.amount + amount, 0)
        })
        |> Repo.update()

      nil ->
        # User has none of this currency, create it with given amount
        insert_user_currency(%{user_id: user_id, currency_id: currency_id, amount: amount})
    end
  end

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

  defp insert_user_currency(attrs) do
    %UserCurrency{}
    |> UserCurrency.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns whether the user can afford the required amounts of the specified currencies.
  """
  def can_afford(user_id, currencies_list) do
    Enum.all?(currencies_list, fn %GameBackend.Users.Currencies.CurrencyCost{
                                    currency_id: currency_id,
                                    amount: amount
                                  } ->
      can_afford(user_id, currency_id, amount)
    end)
  end

  @doc """
  Returns a boolean indicating whether the user can afford the required amount of the specified currency.
  """
  def can_afford(user_id, currency_id, required_amount) do
    user_balance = get_amount_of_currency(user_id, currency_id)
    user_balance >= required_amount
  end

  @doc """
  Substracts all CurrencyCosts from the user.

  Returns {:ok, results} or {:error, "failed"} tuples so it can be used on transactions.
  """
  def substract_currencies(_user_id, []), do: {:ok, []}

  def substract_currencies(user_id, costs) do
    result =
      Enum.map(costs, fn %CurrencyCost{currency_id: currency_id, amount: cost} ->
        add_currency(user_id, currency_id, -cost)
      end)

    if Enum.all?(result, fn
         {:ok, _} -> true
         _ -> false
       end) do
      {:ok,
       Enum.map(result, fn {_ok, user_currency} ->
         UserCurrency.preload_currency(user_currency)
       end)}
    else
      {:error, "failed"}
    end
  end
end
