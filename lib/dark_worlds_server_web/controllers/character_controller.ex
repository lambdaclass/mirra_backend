defmodule DarkWorldsServerWeb.CharacterController do
  use DarkWorldsServerWeb, :controller

  alias DarkWorldsServer.Accounts
  alias DarkWorldsServer.Accounts.User

  def get_player(conn, %{"device_client_id" => device_client_id}) do
    user = DarkWorldsServer.Accounts.get_user_by_device_client_id(device_client_id)
    json(conn, user_response(user))
  end

  def create_player(conn, %{
        "device_client_id" => device_client_id,
        "selected_character" => selected_character
      }) do
    user_params = create_user_data(device_client_id, selected_character)

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        json(conn, user_response(user))

      {:error, _changeset} ->
        json(conn, %{error: "USER_ALREADY_TAKEN"})
    end
  end

  def update_player(
        conn,
        %{"device_client_id" => device_client_id, "selected_character" => selected_character}
      ) do
    user = Accounts.get_user_by_device_client_id(device_client_id)

    if is_nil(user) do
      json(conn, %{error: "INEXISTENT_USER"})
    else
      case Accounts.update_user_selected_character(user, selected_character) do
        {:ok, user} ->
          json(conn, user_response(user))

        {:error, _changeset} ->
          json(conn, %{error: "An error has occurred"})
      end
    end
  end

  defp user_response(nil) do
    %{
      device_client_id: "NOT_FOUND",
      selected_character: "NOT_FOUND"
    }
  end

  defp user_response(%User{device_client_id: device_client_id, selected_character: selected_character}) do
    %{
      device_client_id: device_client_id,
      selected_character: selected_character
    }
  end

  defp create_user_data(device_client_id, selected_character) do
    provisional_password = UUID.uuid4()
    user = UUID.uuid4()

    %{
      email: "test_#{user}@mail.com",
      password: provisional_password,
      device_client_id: device_client_id,
      selected_character: selected_character,
      username: "user_#{user}"
    }
  end
end
