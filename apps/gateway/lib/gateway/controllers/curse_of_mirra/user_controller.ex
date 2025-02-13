defmodule Gateway.Controllers.CurseOfMirra.UserController do
  @moduledoc """
  Controller for CurseOfMirra.User modifications.
  """
  use Gateway, :controller
  alias Gateway.Auth.TokenManager
  alias GameBackend.Users
  alias GameBackend.Rewards
  alias GameBackend.Utils
  alias GameBackend.Units

  action_fallback Gateway.Controllers.FallbackController

  def show(conn, %{"id" => user_id}) do
    game_id = Utils.get_game_id(:curse_of_mirra)

    with {:ok, user} <- Users.get_user_by_id_and_game_id(user_id, game_id) do
      send_resp(conn, 200, Jason.encode!(user))
    end
  end

  def get_unit(conn, %{"user_id" => user_id}) do
    with unit <- Units.get_selected_unit(user_id),
         unit_skin <- Enum.find(unit.skins, fn unit_skin -> unit_skin.selected end) do
      send_resp(conn, 200, Jason.encode!(%{character_name: unit.character.name, skin_name: unit_skin.skin.name}))
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
    with {:ok, %{user: user}} <- Users.insert_curse_user_and_insert_daily_quests(),
         {:ok, unit} <- Units.get_selected_unit(user.id),
         unit_skin <- Enum.find(unit.skins, fn unit_skin -> unit_skin.selected end) do
      gateway_jwt = TokenManager.generate_user_token(user, client_id)

      send_resp(
        conn,
        200,
        Jason.encode!(%{
          user_id: user.id,
          gateway_jwt: gateway_jwt,
          character_name: unit.character.name,
          skin_name: unit_skin.skin.name
        })
      )
    end
  end

  def get_users_leaderboard(conn, _params) do
    users = Users.get_users_sorted_by_total_unit_prestige()
    send_resp(conn, 200, Jason.encode!(%{users: users}))
  end
end
