defmodule Gateway.Test.Champions do
  @moduledoc """
  Test for Champions of Mirra messages.
  """
  use ExUnit.Case

  alias Champions.{Units, Users}
  alias Gateway.Serialization.{Error, Unit, UnitLevelUp, User, WebSocketResponse}
  alias Gateway.SocketTester

  # import Plug.Conn
  # import Phoenix.ConnTest

  setup_all do
    # Start Phoenix endpoint
    {:ok, _} =
      Plug.Cowboy.http(Gateway.Endpoint, [],
        ip: {127, 0, 0, 1},
        port: 4001,
        dispatch: [
          _: [{"/2", Gateway.ChampionsSocketHandler, []}]
        ]
      )

    {:ok, socket_tester} = SocketTester.start_link()

    {:ok, %{socket_tester: socket_tester}}
  end

  test "users", %{socket_tester: socket_tester} do
    # Create our user
    :ok = SocketTester.create_user(socket_tester, "Username")
    fetch_last_message(socket_tester)
    assert_receive %WebSocketResponse{response_type: {:user, %User{}}}

    fetch_last_message(socket_tester)
    %WebSocketResponse{response_type: {:user, user}} = get_last_message()

    # Creating another user with the same name fails
    :ok = SocketTester.create_user(socket_tester, "Username")
    fetch_last_message(socket_tester)
    assert_receive %WebSocketResponse{response_type: {:error, %Error{reason: "username_taken"}}}

    # Get user by name
    :ok = SocketTester.get_user_by_username(socket_tester, "Username")
    fetch_last_message(socket_tester)
    assert_receive %WebSocketResponse{response_type: {:user, ^user}}
  end

  test "units", %{socket_tester: socket_tester} do
    # Create our user
    :ok = SocketTester.create_user(socket_tester, "UnitsUser")
    fetch_last_message(socket_tester)
    assert_receive %WebSocketResponse{response_type: {:user, %User{}}}

    # Get the user and a unit
    fetch_last_message(socket_tester)
    %WebSocketResponse{response_type: {:user, user}} = get_last_message()

    gold = Users.get_amount_of_currency_by_name!(user.id, "Gold")
    [unit | _] = user.units
    slot = unit.slot
    level = unit.unit_level

    # Unit is selected by default (this will change when we remove sample data in user creation)
    assert unit.selected

    # Unselect the unit
    :ok = SocketTester.unselect_unit(socket_tester, user.id, unit.id)
    fetch_last_message(socket_tester)
    assert_receive %WebSocketResponse{response_type: {:unit, %Unit{}}}

    fetch_last_message(socket_tester)
    %WebSocketResponse{response_type: {:unit, unit}} = get_last_message()

    assert not unit.selected
    # Protobuf doesn't support nil values, returns zero instead
    assert unit.slot == 0

    :ok = SocketTester.select_unit(socket_tester, user.id, unit.id, slot)
    fetch_last_message(socket_tester)
    assert_receive %WebSocketResponse{response_type: {:unit, %Unit{}}}

    fetch_last_message(socket_tester)
    %WebSocketResponse{response_type: {:unit, unit}} = get_last_message()

    assert unit.selected
    assert unit.slot == slot

    # Level up the unit
    {_gold_id, level_up_cost} = Units.calculate_level_up_cost(unit)

    :ok = SocketTester.level_up_unit(socket_tester, user.id, unit.id)
    fetch_last_message(socket_tester)
    assert_receive %WebSocketResponse{response_type: {:unit_level_up, %UnitLevelUp{}}}

    fetch_last_message(socket_tester)

    %WebSocketResponse{
      response_type: {:unit_level_up, %UnitLevelUp{unit: unit, user_currency: user_currency}}
    } = get_last_message()

    assert unit.unit_level == level + 1
    assert user_currency.currency.name == "Gold"
    assert user_currency.amount == gold - level_up_cost
  end

  defp get_last_message() do
    receive do
      message ->
        message
    after
      5000 ->
        raise "No message"
    end
  end

  defp fetch_last_message(socket_tester) do
    :timer.sleep(50)
    send(socket_tester, {:last_message, self()})
  end
end
