defmodule Gateway.Controllers.Users.CurrencyController do
  use Gateway, :controller

  alias GameBackend.Users.Currencies.UserCurrency
  alias GameBackend.Users.Currencies

  @moduledoc """
    Controller to control currency changes in users
  """

  def modify_currency(conn, %{
        "currency_name" => currencty_name,
        "amount" => amount,
        "user_id" => user_id,
        "game_name" => game_name
      }) do
    case Currencies.add_currency_by_name_and_game(user_id, game_name, currencty_name, amount) do
      {:ok, %UserCurrency{}} -> send_resp(conn, 200, "Currency added")
      _ -> send_resp(conn, 400, "Couldn't add currency")
    end
  end
end
