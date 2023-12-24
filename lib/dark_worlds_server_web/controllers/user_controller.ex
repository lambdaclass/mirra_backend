defmodule DarkWorldsServerWeb.UserController do
  use DarkWorldsServerWeb, :controller

  alias DarkWorldsServer.Accounts
  alias DarkWorldsServer.Accounts.User
  alias DarkWorldsServer.Config.Characters
  alias DarkWorldsServer.Units
  alias DarkWorldsServer.Utils

  def get_user(conn, %{"device_client_id" => device_client_id}) do
    user = DarkWorldsServer.Accounts.get_user_by_device_client_id(device_client_id)
    json(conn, user_response(user))
  end

  def create_user(conn, %{
        "device_client_id" => device_client_id,
        "selected_character" => selected_character
      }) do
    user_params = create_user_data(device_client_id)

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        Units.insert_unit(%{
          level: 1,
          selected: true,
          slot: nil,
          user_id: user.id,
          character_id:
            selected_character
            |> Utils.Characters.game_character_name_to_character_name()
            |> Characters.get_character_by_name()
            |> Map.get(:id)
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
        case Units.replace_selected_character(
               Utils.Characters.game_character_name_to_character_name(selected_character),
               user.id,
               %{level: 1}
             ) do
          {:ok, _unit} ->
            json(conn, user_response(user))

          {:error, _changeset} ->
            json(conn, %{error: "An error has occurred"})
        end
    end
  end

  def add_selected_unit(
        conn,
        %{"device_client_id" => device_client_id, "unit_id" => added_unit} = params
      ) do
    case Accounts.get_user_by_device_client_id(device_client_id) do
      nil ->
        json(conn, %{error: "INEXISTENT_USER"})

      user ->
        unit_params = %{selected: true}

        unit_params =
          case Map.get(params, "slot") do
            nil -> unit_params
            slot -> Map.put(unit_params, :slot, slot)
          end

        case Units.get_unit(added_unit) |> Units.update_unit(unit_params) do
          {:ok, _unit} ->
            json(conn, user_response(user))

          {:error, _changeset} ->
            json(conn, %{error: "An error has occurred"})
        end
    end
  end

  def remove_selected_unit(
        conn,
        %{"device_client_id" => device_client_id, "unit_id" => removed_unit} = params
      ) do
    case Accounts.get_user_by_device_client_id(device_client_id) do
      nil ->
        json(conn, %{error: "INEXISTENT_USER"})

      user ->
        unit_params = %{selected: false}

        unit_params =
          case Map.get(params, "slot") do
            nil -> unit_params
            slot -> Map.put(unit_params, :slot, slot)
          end

        case Units.get_unit(removed_unit) |> Units.update_unit(unit_params) do
          {:ok, _unit} ->
            json(conn, user_response(user))

          {:error, _changeset} ->
            json(conn, %{error: "An error has occurred"})
        end
    end
  end

  def get_units(conn, %{"device_client_id" => device_client_id}) do
    case Accounts.get_user_by_device_client_id(device_client_id) do
      nil ->
        json(conn, %{error: "INEXISTENT_USER"})

      user ->
        units = Units.get_units(user.id)

        json(
          conn,
          Enum.map(
            units,
            &%{id: &1.id, character: &1.character.name, selected: &1.selected, slot: &1.slot, level: &1.level}
          )
        )
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

    if is_nil(selected_unit),
      do: %{device_client_id: device_client_id},
      else: %{
        device_client_id: device_client_id,
        selected_character: Utils.Characters.character_name_to_game_character_name(selected_unit.character.name)
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
