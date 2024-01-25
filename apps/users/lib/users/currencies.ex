defmodule Users.Currencies do
  @moduledoc """
  The Currencies context.
  """

  import Ecto.Query, warn: false

  alias Users.Currencies.UserCurrency
  alias Users.Currencies.Currency
  alias Users.Repo

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
      )

  def add_currency(user_id, currency_id, amount) do
    case Repo.one(
           from(uc in UserCurrency,
             where: uc.user_id == ^user_id and uc.currency_id == ^currency_id
           )
         ) do
      nil ->
        # User has none of this currency, create it with given amount
        if amount > 0,
          do: insert_user_currency(%{user_id: user_id, currency_id: currency_id, amount: amount})

      user_currency ->
        user_currency
        |> UserCurrency.update_changeset(%{amount: max(user_currency.amount + amount, 0)})
        |> Repo.update()
    end
  end

  defp insert_user_currency(attrs) do
    %UserCurrency{}
    |> UserCurrency.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns a boolean indicating whether the user can afford the required amount of the specified currency.
  """
  def can_afford(user_id, currency_id, required_amount) do
    user_balance = get_amount_of_currency(user_id, currency_id)
    user_balance >= required_amount
  end
end
