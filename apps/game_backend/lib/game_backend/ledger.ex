defmodule GameBackend.Ledger do
  @moduledoc """
  """

  import Ecto.Query
  alias GameBackend.Users.Currencies.UserCurrencyCap
  alias GameBackend.Users.Currencies.UserCurrency
  alias GameBackend.Ledger.Transaction
  alias Ecto.Multi
  alias GameBackend.Repo

  def get_user_transactions(user_id) do
    q = from t in Transaction,
      where: t.user_id == ^user_id,
      order_by: [desc: :inserted_at]

    Repo.all(q)
  end

  #
  # Returns the current balance for a given user of all currencies. Returns a list of tuples where the first element is the currency id and the second one is the balance of that currency
  # This can be computed on-the-fly or have this cached in each UserCurrency.
  #
  def get_currency_balances(user_id) do
    q =
      from(t in Transaction,
        where: t.user_id == ^user_id,
        group_by: t.currency_id,
        select: {t.currency_id, fragment("SUM(CASE WHEN type = 'credit' THEN amount ELSE -amount END)")}
      )

    Repo.all(q)
  end

  #
  # Returns the current balance for a given user of a specific currency
  # This can be computed on-the-fly or have this cached in UserCurrency.
  #
  def get_balance(user_id, currency_id) do
    q =
      from(t in Transaction,
        where: t.user_id == ^user_id and t.currency_id == ^currency_id,
        group_by: t.currency_id,
        select: fragment("SUM(CASE WHEN type = 'credit' THEN amount ELSE -amount END)")
      )

    Repo.one(q)
  end

  def register_currency_spent(user_id, currency_id, amount_spent, description) do
    transaction_changeset = %Transaction{}
      |> Transaction.changeset(%{
        user_id: user_id,
        currency_id: currency_id,
        type: :debit,
        amount: amount_spent,
        description: description,
        timestamp: DateTime.utc_now()
      })

    # Question: do we include the action we want to do (e.g. buying a skin) in the same transaction?
    Multi.new()
    |> Multi.run(:set_serializable_step, fn repo, _ ->
      # This is needed because in tests we run inside a transaction,
      # nesting transactions or changing isolation level doesn't work
      if Application.get_env(:game_backend, :env) == :test do
        {:ok, :skip}
      else
        {:ok, repo.query!("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")}
      end
    end)
    |> Multi.run(:user_currency, fn repo, _changes -> 
      {:ok, repo.get_by(UserCurrency, [user_id: user_id, currency_id: currency_id])}
    end)
    |> Multi.run(:has_enough_currency?, fn _repo, %{user_currency: user_currency} -> 
      if not is_nil(user_currency) and user_currency.amount >= amount_spent do
        {:ok, true}
      else
        {:error, :not_enough_currency}
      end
    end)
    |> Multi.update(:remove_currency_from_user, fn %{user_currency: user_currency} -> 
      Ecto.Changeset.change(user_currency, amount: user_currency.amount - amount_spent)
    end)
    |> Multi.insert(:insert_currency_removal_into_ledger, transaction_changeset)
    |> Repo.transaction()
  end

  def register_currency_earned(user_id, currency_id, amount_earned, description) do
    transaction_changeset = %Transaction{}
      |> Transaction.changeset(%{
        user_id: user_id,
        currency_id: currency_id,
        type: :credit,
        amount: amount_earned,
        description: description,
        timestamp: DateTime.utc_now()
      })

    # Question: do we include the action we want to do (e.g. buying a skin) in the same transaction?
    Multi.new()
    |> Multi.run(:set_serializable_step, fn repo, _ ->
      # This is needed because in tests we run inside a transaction,
      # nesting transactions or changing isolation level doesn't work
      if Application.get_env(:game_backend, :env) == :test do
        {:ok, :skip}
      else
        {:ok, repo.query!("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")}
      end
    end)
    |> Multi.run(:user_currency, fn repo, _changes -> 
      user_currency = repo.get_by(UserCurrency, [user_id: user_id, currency_id: currency_id])

      if is_nil(user_currency) do
        %UserCurrency{}
        |> UserCurrency.changeset(%{user_id: user_id, currency_id: currency_id, amount: 0})
        |> repo.insert()
      else
        {:ok, user_currency}
      end
    end)
    |> Multi.run(:user_currency_cap, fn repo, _changes -> 
      {:ok, repo.get_by(UserCurrencyCap, [user_id: user_id, currency_id: currency_id])}
    end)
    |> Multi.update(:add_currency_to_user, fn %{user_currency: user_currency, user_currency_cap: user_currency_cap} -> 
      case user_currency_cap do
        nil ->
          Ecto.Changeset.change(user_currency, amount: user_currency.amount + amount_earned)
        %UserCurrencyCap{cap: cap} ->
          Ecto.Changeset.change(user_currency, amount: min(user_currency.amount + amount_earned, cap))
      end
    end)
    |> Multi.insert(:insert_currency_income_into_ledger, transaction_changeset)
    |> Repo.transaction()
  end
end
