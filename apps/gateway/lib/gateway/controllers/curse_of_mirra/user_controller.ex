defmodule Gateway.Controllers.CurseOfMirra.UserController do
  @moduledoc """
  Controller for CurseOfMirra.User modifications.
  """
  use Gateway, :controller
  alias Gateway.Auth.TokenManager
  alias GameBackend.Users
  alias GameBackend.Rewards
  alias GameBackend.Utils

  action_fallback Gateway.Controllers.FallbackController

  def claim_daily_reward(conn, %{"user_id" => user_id}) do
    with {:ok, user} <- Users.get_user(user_id),
         {:ok, :can_claim} <- Rewards.user_can_claim(user),
         {:ok, daily_reward} <- Rewards.claim_daily_reward(user),
         {:ok, _user_updates_map} <- Rewards.update_user_due_to_daily_rewards_claim(user, daily_reward) do
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

  def create_guest_user(conn, _params) do
    with {:ok, user} <- Users.create_guest_user(),
         gateway_jwt = TokenManager.generate_user_token(user) do
      send_resp(conn, 200, Jason.encode!(%{user_id: user.id, gateway_jwt: gateway_jwt}))
    end
  end
end
