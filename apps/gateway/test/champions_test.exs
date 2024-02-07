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

    :ok
  end

  setup do
    {:ok, socket_tester} = SocketTester.start_link()

    {:ok, %{socket_tester: socket_tester}}
  end

  describe "users" do
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
  end

  describe "units" do
    test "unit selection", %{socket_tester: socket_tester} do
      user = Users.register("SelectUser")

      [unit_to_unselect | _] = user.units
      slot = unit_to_unselect.slot

      # Unit is selected by default (this will change when we remove sample data in user creation)
      assert unit_to_unselect.selected

      # Unselect the unit
      :ok = SocketTester.unselect_unit(socket_tester, user.id, unit_to_unselect.id)
      fetch_last_message(socket_tester)
      assert_receive %WebSocketResponse{response_type: {:unit, %Unit{}}}

      fetch_last_message(socket_tester)
      %WebSocketResponse{response_type: {:unit, unselected_unit}} = get_last_message()

      assert not unselected_unit.selected
      # Protobuf doesn't support nil values, returns zero instead
      assert unselected_unit.slot == 0

      :ok = SocketTester.select_unit(socket_tester, user.id, unselected_unit.id, slot)
      fetch_last_message(socket_tester)
      assert_receive %WebSocketResponse{response_type: {:unit, %Unit{}}}

      fetch_last_message(socket_tester)
      %WebSocketResponse{response_type: {:unit, selected_unit}} = get_last_message()

      assert selected_unit.selected
      assert selected_unit.slot == slot
    end

    test "unit level up", %{socket_tester: socket_tester} do
      user = Users.register("LevelUpUser")
      Users.add_currency_by_name!(user.id, "Gold", 9999)

      {:ok, unit} =
        GameBackend.Units.insert_unit(%{
          user_id: user.id,
          unit_level: 9,
          tier: 0,
          selected: false,
          character_id: GameBackend.Units.Characters.get_character_by_name("Muflus").id
        })

      gold = Users.get_amount_of_currency_by_name!(user.id, "Gold")
      level = unit.unit_level

      # Level up the unit
      [{_gold_id, level_up_cost}] = Units.calculate_level_up_cost(unit)

      :ok = SocketTester.level_up_unit(socket_tester, user.id, unit.id)
      fetch_last_message(socket_tester)
      assert_receive %WebSocketResponse{response_type: {:unit_level_up, %UnitLevelUp{}}}

      fetch_last_message(socket_tester)

      %WebSocketResponse{
        response_type: {:unit_level_up, %UnitLevelUp{unit: unit, user_currency: [user_currency]}}
      } = get_last_message()

      assert unit.unit_level == level + 1
      assert user_currency.currency.name == "Gold"
      assert user_currency.amount == gold - level_up_cost

      # Cannot level up because unit is level 10 with tier 0
      assert unit.unit_level == 10
      assert unit.tier == 0
      :ok = SocketTester.level_up_unit(socket_tester, user.id, unit.id)
      fetch_last_message(socket_tester)
      assert_receive %WebSocketResponse{response_type: {:error, %Error{reason: "cant_level_up"}}}
    end
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
