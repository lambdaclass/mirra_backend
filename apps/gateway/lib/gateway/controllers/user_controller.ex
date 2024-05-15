defmodule Gateway.Controllers.UserController do
  @moduledoc """
  Controller for User modifications.
  """
  use Gateway, :controller
  alias GameBackend.Users
  alias GameBackend.Rewards
  alias GameBackend.Utils
  alias GameBackend.Users.Currencies
  alias GameBackend.Users.Currencies.UserCurrency

  action_fallback Gateway.Controllers.FallbackController

  def update(conn, params) do
    with {:ok, user} <- Users.get_user(params["user_id"]),
         {:ok, user} <- Users.update_user(user, params) do
      send_resp(conn, 200, Jason.encode!(user.id))
    end
  end

  def claim_daily_reward(conn, %{"user_id" => user_id}) do
    with {:ok, user} <- Users.get_user(user_id),
         {:ok, :can_claim} <- Rewards.user_can_claim(user),
         {:ok, daily_reward} <- Rewards.claim_daily_reward(user),
         {:ok, user} <-
           Users.update_user(user, %{
             last_daily_reward_claim_at: DateTime.utc_now(),
             last_daily_reward_claim: daily_reward["day"]
           }),
         {:ok, %UserCurrency{}} <-
           Currencies.add_currency_by_name_and_game!(
             user_id,
             daily_reward["currency"],
             Utils.get_game_id(:curse_of_mirra),
             daily_reward["amount"]
           ) do
      send_resp(conn, 200, Jason.encode!(user.id))
    end
  end

  def get_daily_reward_status(conn, %{"user_id" => user_id}) do
    with {:ok, user} <- Users.get_user(user_id) do
      user_daily_reward_status =
        Utils.get_daily_rewards_config()
        |> Rewards.mark_user_daily_rewards_as_completed(user)

      send_resp(conn, 200, Jason.encode!(user_daily_reward_status))
    end
  end
end
