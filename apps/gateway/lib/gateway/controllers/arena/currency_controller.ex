defmodule Gateway.Curse.Controllers.Users.CurrencyController do
  @moduledoc """
    Controller to control currency changes in users
  """

  use Gateway, :controller

  alias GameBackend.Users
  alias GameBackend.Utils
  alias GameBackend.Users.Currencies

  def modify_currency(conn, %{
        "currency_name" => currencty_name,
        "amount" => amount,
        "user_id" => user_id
      }) do
    game_id = Utils.get_game_id(:curse_of_mirra)

    with {:get_user, {:ok, user}} <- {:get_user, Users.get_user(user_id)},
         {:curse_user, ^game_id} <- {:curse_user, user.game_id},
         {:add_currency, {:ok, user_currency}} <-
           {:add_currency, Currencies.add_currency_by_name_and_game(user_id, currencty_name, user.game_id, amount)} do
      send_resp(conn, 200, Jason.encode!(Map.take(user_currency, [:amount, :user_id, :currency_id])))
    else
      {:get_user, _} -> send_resp(conn, 404, "User not found")
      {:curse_user, _} -> send_resp(conn, 400, "User from another game")
      {:add_currency, _} -> send_resp(conn, 400, "Couldn't add currency")
    end
  end
end
