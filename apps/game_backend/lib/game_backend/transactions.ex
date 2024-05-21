defmodule GameBackend.Transactions do
  def curse_create_transaction(amount, user_id, demo_currency_id) do
    create_transaction(GameBackend.Curse.CurrencyTransaction, amount, user_id, demo_currency_id)
  end

  def champions_create_transaction(amount, user_id, demo_currency_id) do
    create_transaction(GameBackend.Champions.CurrencyTransaction, amount, user_id, demo_currency_id)
  end

  defp create_transaction(module, amount, user_id, demo_currency_id) do
    struct(module)
    |> module.changeset(%{amount: amount, user_id: user_id, demo_currency_id: demo_currency_id})
    |> GameBackend.Repo.insert()
  end
end
