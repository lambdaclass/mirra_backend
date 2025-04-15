defmodule Gateway.Controllers.CurseOfMirra.CharacterController do
  @moduledoc """
  Controller for Character modifications.
  """
  use Gateway, :controller
  alias GameBackend.Units

  action_fallback Gateway.Controllers.FallbackController

  def select(conn, params) do
    with {:ok, units} <- Units.list_units_by_user(params["user_id"]),
         {:ok, _transaction} <- Units.select_unit_character(units, params["character_name"]) do
      send_resp(conn, 200, Jason.encode!(%{character_name: params["character_name"]}))
    end
  end

  def select_skin(conn, params) do
    with {:ok, unit} <- Units.get_unit_by_character_name(params["character_name"], params["user_id"]),
         {:ok, :skin_exists} <- Units.has_skin?(unit, params["skin_name"]),
         {:ok, _transaction} <- Units.select_unit_skin(unit, params["skin_name"]) do
      send_resp(conn, 200, Jason.encode!(%{character_name: params["character_name"], skin_name: params["skin_name"]}))
    end
  end

  def level_up(conn, params) do
    with {:ok, unit} <- Units.get_unit_by_character_name(params["character_name"], params["user_id"]),
         {:ok, %{unit: leveled_up_unit, user_currency: user_currencies}} <- Units.level_up(params["user_id"], unit.id) do
      new_balances =
        user_currencies
        |> Enum.map(fn user_currency ->
          %{amount: user_currency.amount, currency: %{name: user_currency.currency.name}}
        end)

      send_resp(
        conn,
        200,
        Jason.encode!(%{
          character_name: params["character_name"],
          new_level: leveled_up_unit.level,
          new_currency_balance: new_balances
        })
      )
    else
      {:error, :no_more_levels} ->
        send_resp(conn, 400, "Cannot further level up")

      {:error, :cant_afford} ->
        send_resp(conn, 400, "Cannot afford levelling up")
    end
  end

  def level_up_settings(conn, _params) do
    send_resp(conn, 200, Jason.encode!(%{levels: Units.get_level_up_settings()}))
  end
end
