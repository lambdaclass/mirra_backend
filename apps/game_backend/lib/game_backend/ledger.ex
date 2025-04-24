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
    q =
      from(t in Transaction,
        where: t.user_id == ^user_id,
        order_by: [desc: :inserted_at]
      )

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

  @doc """
  Returns an `Ecto.Multi` that will perform all checks, substract the specified
  currencies to the user and adds a register to the transaction log.

  To ensure transaction isolation you can set the isolation level with:

    Multi.run(:set_serializable_step, fn repo, _ ->
      # This is needed because in tests we run inside a transaction,
      # nesting transactions or changing isolation level doesn't work
      if Application.get_env(:game_backend, :env) == :test do
        {:ok, :skip}
      else
        {:ok, repo.query!("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")}
      end
    end)
  
  """
  def register_currencies_spent_multi(multi, user_id, currency_costs, description) do
    Enum.reduce(currency_costs, multi, fn currency_cost, acc ->
      transaction_changeset =
        %Transaction{}
        |> Transaction.changeset(%{
          user_id: user_id,
          currency_id: currency_cost.currency_id,
          type: :debit,
          amount: currency_cost.amount,
          description: description,
          timestamp: DateTime.utc_now()
        })

      acc
      |> Multi.run({:user_currency, currency_cost.currency_id}, fn repo, _changes ->
        {:ok, repo.get_by(UserCurrency, user_id: user_id, currency_id: currency_cost.currency_id)}
      end)
      |> Multi.run({:has_enough_currency?, currency_cost.currency_id}, fn _repo, changes ->
        user_currency = Map.get(changes, {:user_currency, currency_cost.currency_id})

        if not is_nil(user_currency) and user_currency.amount >= currency_cost.amount do
          {:ok, true}
        else
          {:error, :not_enough_currency}
        end
      end)
      |> Multi.update({:remove_currency_from_user, currency_cost.currency_id}, fn changes ->
        user_currency = Map.get(changes, {:user_currency, currency_cost.currency_id})
        Ecto.Changeset.change(user_currency, amount: user_currency.amount - currency_cost.amount)
      end)
      |> Multi.insert({:insert_currency_removal_into_ledger, currency_cost.currency_id}, transaction_changeset)
    end)
  end

  def register_currencies_spent(user_id, currency_costs, description) do
    register_currencies_spent_multi(Multi.new(), user_id, currency_costs, description)
    |> Repo.transaction()
  end

  def register_currencies_spent(multi, user_id, currency_costs, description) do
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
    |> Multi.merge(fn _ -> multi end)
    |> register_currencies_spent_multi(user_id, currency_costs, description)
  end

  @doc """
  Returns an `Ecto.Multi` that will perform all checks, add the specified
  currencies to the user and adds a register to the transaction log.

  To ensure transaction isolation you can set the isolation level with:

    Multi.run(:set_serializable_step, fn repo, _ ->
      # This is needed because in tests we run inside a transaction,
      # nesting transactions or changing isolation level doesn't work
      if Application.get_env(:game_backend, :env) == :test do
        {:ok, :skip}
      else
        {:ok, repo.query!("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")}
      end
    end)
  
  """
  def register_currency_earned_multi(multi, user_id, earned_currencies, description) do
    Enum.reduce(earned_currencies, multi, fn currency_earned, acc ->
      transaction_changeset =
        %Transaction{}
        |> Transaction.changeset(%{
          user_id: user_id,
          currency_id: currency_earned.currency_id,
          type: :credit,
          amount: currency_earned.amount,
          description: description,
          timestamp: DateTime.utc_now()
        })

      acc
      |> Multi.run({:user_currency, currency_earned.currency_id}, fn repo, _changes ->
        user_currency = repo.get_by(UserCurrency, user_id: user_id, currency_id: currency_earned.currency_id)

        if is_nil(user_currency) do
          %UserCurrency{}
          |> UserCurrency.changeset(%{user_id: user_id, currency_id: currency_earned.currency_id, amount: 0})
          |> repo.insert()
        else
          {:ok, user_currency}
        end
      end)
      |> Multi.run({:user_currency_cap, currency_earned.currency_id}, fn repo, _changes ->
        {:ok, repo.get_by(UserCurrencyCap, user_id: user_id, currency_id: currency_earned.currency_id)}
      end)
      |> Multi.update({:add_currency_to_user, currency_earned.currency_id}, fn changes ->
        user_currency = Map.get(changes, {:user_currency, currency_earned.currency_id})
        user_currency_cap = Map.get(changes, {:user_currency_cap, currency_earned.currency_id})

        case user_currency_cap do
          nil ->
            Ecto.Changeset.change(user_currency, amount: user_currency.amount + currency_earned.amount)

          %UserCurrencyCap{cap: cap} ->
            Ecto.Changeset.change(user_currency, amount: min(user_currency.amount + currency_earned.amount, cap))
        end
      end)
      |> Multi.insert({:insert_currency_income_into_ledger, currency_earned.currency_id}, transaction_changeset)
    end)
  end

  def register_currency_earned(user_id, earned_currencies, description) do
    register_currency_earned_multi(Multi.new(), user_id, earned_currencies, description)
    |> Repo.transaction()
  end

  def register_currency_earned(multi, user_id, currency_costs, description) do
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
    |> Multi.merge(fn _ -> multi end)
    |> register_currency_earned_multi(user_id, currency_costs, description)
  end
end
