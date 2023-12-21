defmodule DarkWorldsServerWeb.CharacterController do
  use DarkWorldsServerWeb, :controller

  alias DarkWorldsServer.Accounts
  alias DarkWorldsServer.Accounts.User
  alias DarkWorldsServer.Config.Characters
  alias DarkWorldsServer.Units
  alias DarkWorldsServer.Utils

  def get_player(conn, %{"device_client_id" => device_client_id}) do
    user = DarkWorldsServer.Accounts.get_user_by_device_client_id(device_client_id)
    json(conn, user_response(user))
  end

  def create_player(conn, %{
        "device_client_id" => device_client_id,
        "selected_character" => selected_character
      }) do
    user_params = create_user_data(device_client_id)

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        Units.insert_unit(%{
          level: 1,
          selected: true,
          position: nil,
          user_id: user.id,
          character_id: Characters.get_character_by_name(String.downcase(selected_character)).id
        })

        json(conn, user_response(user))

      {:error, _changeset} ->
        json(conn, %{error: "USER_ALREADY_TAKEN"})
    end
  end

  def update_selected_character(
        conn,
        %{"device_client_id" => device_client_id, "selected_character" => selected_character}
      ) do
    case Accounts.get_user_by_device_client_id(device_client_id) do
      nil ->
        json(conn, %{error: "INEXISTENT_USER"})

      user ->
        case Units.replace_selected_character(String.downcase(selected_character), user.id, %{level: 1}) do
          {:ok, _unit} ->
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

  defp user_response(%User{device_client_id: device_client_id} = user) do
    selected_unit = Units.get_selected_unit(user.id)

    %{
      device_client_id: device_client_id,
      selected_character: Utils.Characters.transform_character_name_to_game_character_name(selected_unit.character.name)
    }
  end

  defp create_user_data(device_client_id) do
    provisional_password = UUID.uuid4()
    user = UUID.uuid4()

    %{
      email: "test_#{user}@mail.com",
      password: provisional_password,
      device_client_id: device_client_id,
      username: "user_#{user}"
    }
  end
end
