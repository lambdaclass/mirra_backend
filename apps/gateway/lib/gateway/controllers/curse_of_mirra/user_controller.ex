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

  def show(conn, %{"id" => user_id}) do
    game_id = Utils.get_game_id(:curse_of_mirra)

    with {:ok, user} <- Users.get_user_by_id_and_game_id(user_id, game_id) do
      send_resp(conn, 200, Jason.encode!(user))
    end
  end

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

  def create_guest_user(conn, %{"client_id" => client_id}) do
    with {:ok, %{user: user}} <- Users.insert_curse_user_and_insert_daily_quests() do
      gateway_jwt = TokenManager.generate_user_token(user, client_id)
      random_character = Enum.find(user.units, fn unit -> unit.character.name == "h4ck" end).character
      default_skin = Enum.find(user.user_skins, fn user_skin -> user_skin.skin.character_id == random_character.id and user_skin.skin.is_default end)
      send_resp(conn, 200, Jason.encode!(%{user_id: user.id, gateway_jwt: gateway_jwt, character: %{character_name: random_character.name, skin_id: default_skin}}))
    end
  end

  def get_users_leaderboard(conn, _params) do
    users = Users.get_users_sorted_by_total_unit_prestige()
    send_resp(conn, 200, Jason.encode!(%{users: users}))
  end
end
