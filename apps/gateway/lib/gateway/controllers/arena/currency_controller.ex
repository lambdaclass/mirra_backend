defmodule Gateway.Controllers.Arena.CurrencyController do
  use Gateway, :controller

  alias GameBackend.Users.Currencies.UserCurrency
  alias GameBackend.Users.Currencies

  @moduledoc """
    Controller to control currency changes in users
  """

  def modify_currency(conn, %{"currency_name" => currencty_name, "amount" => amount, "user_id" => user_id}) do
    with {:value, {amount, _}} <- {:value, Integer.parse(amount)},
         {:add_currency, {:ok, %UserCurrency{}}} <-
           {:add_currency, Currencies.add_currency_by_name(user_id, currencty_name, amount)} do
      send_resp(conn, 200, "Currency added")
    else
      {:value, :error} -> send_resp(conn, 400, "Invalid value")
      {:add_currency, nil} -> send_resp(conn, 400, "Currency not found")
    end
  end
end
