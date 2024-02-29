defmodule GameBackend.Users.Currencies do
  @moduledoc """
  The Currencies context.
  """

  import Ecto.Query, warn: false

  alias GameBackend.Users.Currencies.UserCurrency
  alias GameBackend.Users.Currencies.Currency
  alias GameBackend.Users.Currencies.CurrencyCost
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
  Adds (or substracts) the given amount of currency to a user.
  Creates the relational table if it didn't exist previously.
  """
  def add_currency(user_id, currency_id, amount) do
    result =
      with %UserCurrency{} = user_currency <- get_user_currency(user_id, currency_id),
           changeset <-
             UserCurrency.update_changeset(user_currency, %{
               amount: max(user_currency.amount + amount, 0)
             }) do
        Repo.update(changeset)
      else
        nil ->
          # User has none of this currency, create it with given amount
          insert_user_currency(%{user_id: user_id, currency_id: currency_id, amount: amount})
      end

    case result do
      {:error, reason} -> {:error, reason}
      {:ok, currency} -> {:ok, currency |> Repo.preload([:currency])}
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

  defp insert_user_currency(attrs) do
    %UserCurrency{}
    |> UserCurrency.changeset(attrs)
    |> Repo.insert()
  end

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
  Substracts all CurrencyCosts from the user.

  If all calls succeed, `{:ok, results}` is returned, where `results` is a %UserCurrency{} list.
  If any of the calls fail, `{:error, "failed"}` is returned instead.

  Note that on failure, the succesful calls still take effect. Because of this, it's heavily
  advised that you use this function inside a Multi transaction, specially if you are combining
  it with other DB acesses.

  ## Examples

      iex> Ecto.Multi.new()
      |> Ecto.Multi.run(:some_other_operation, fn _, _ -> other_operation() end)
      |> Ecto.Multi.run(:user_currency, fn _, _ ->
        Currencies.substract_currencies(user_id, [
          %CurrencyCost{currency_id: currency_id, amount: amount}
        ])
      end)
      |> GameBackend.Repo.transaction()
      {:ok, %{user_currency: [%UserCurrency{}]}
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
      {:ok, Enum.map(result, &elem(&1, 1))}
    else
      {:error, "failed"}
    end
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
  Add amount of currency to user by its name.
  """
  def add_currency_by_name!(user_id, currency_name, amount),
    do:
      user_id
      |> add_currency(get_currency_by_name!(currency_name).id, amount)
end
