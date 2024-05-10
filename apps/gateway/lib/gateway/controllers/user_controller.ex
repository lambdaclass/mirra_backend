defmodule Gateway.Controllers.UserController do
  @moduledoc """
  Controller for User modifications.
  """
  use Gateway, :controller
  alias GameBackend.Users
  alias GameBackend.Rewards

  action_fallback Gateway.Controllers.FallbackController

  def update(conn, params) do
    with {:ok, user} <- Users.get_user(params["user_id"]),
         {:ok, user} <- Users.update_user(user, params) do
      send_resp(conn, 200, Jason.encode!(user.id))
    end
  end

  def claim_daily_reward(conn, %{"user_id" => user_id}) do
    with {:ok, user} <- Users.get_user(user_id),
         {:ok, :can_claim} <- Rewards.user_claimed_today(user),
         {:ok, daily_reward} <- Rewards.claim_daily_reward(user),
         {:ok, user} <-
           Users.update_user(user, %{
             last_daily_reward_claim_at: DateTime.utc_now(),
             last_daily_reward_claim: daily_reward
           }) do
      send_resp(conn, 200, Jason.encode!(user.id))
    end
  end
end
