defmodule Gateway.Test.Champions do
  @moduledoc """
  Test for Champions of Mirra messages.
  """
  use ExUnit.Case

  alias GameBackend.Users.Currencies.CurrencyCost
  alias GameBackend.Units.Characters
  alias GameBackend.Repo
  alias GameBackend.Users.Currencies
  alias Champions.{Units, Users}

  alias Gateway.Serialization.{
    Box,
    Boxes,
    Currency,
    Error,
    Unit,
    UnitAndCurrencies,
    User,
    UserCurrency,
    UserAndUnit,
    WebSocketResponse
  }

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
    test "selection", %{socket_tester: socket_tester} do
      {:ok, user} = Users.register("SelectUser")

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

    test "progression", %{socket_tester: socket_tester} do
      muflus = GameBackend.Units.Characters.get_character_by_name("Muflus")
      {:ok, user} = Users.register("LevelUpUser")
      Users.add_currency_by_name!(user.id, "Gold", 9999)

      {:ok, unit} =
        GameBackend.Units.insert_unit(%{
          user_id: user.id,
          unit_level: 19,
          tier: 1,
          rank: 2,
          selected: false,
          character_id: muflus.id
        })

      gold = Users.get_amount_of_currency_by_name!(user.id, "Gold")
      level = unit.unit_level

      #### Level up
      [%CurrencyCost{currency_id: _gold_id, amount: level_up_cost}] =
        Units.calculate_level_up_cost(unit)

      :ok = SocketTester.level_up_unit(socket_tester, user.id, unit.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:unit_and_currencies, %UnitAndCurrencies{}}
      }

      fetch_last_message(socket_tester)

      %WebSocketResponse{
        response_type:
          {:unit_and_currencies, %UnitAndCurrencies{unit: unit, user_currency: [user_currency]}}
      } = get_last_message()

      assert unit.unit_level == level + 1
      assert user_currency.currency.name == "Gold"
      assert user_currency.amount == gold - level_up_cost

      # Cannot level up because unit is level 20 with tier 1
      assert unit.unit_level == 20
      assert unit.tier == 1
      :ok = SocketTester.level_up_unit(socket_tester, user.id, unit.id)
      fetch_last_message(socket_tester)
      assert_receive %WebSocketResponse{response_type: {:error, %Error{reason: "cant_level_up"}}}

      #### Tier up

      user_gold = Users.get_amount_of_currency_by_name!(user.id, "Gold")
      user_gems = Users.get_amount_of_currency_by_name!(user.id, "Gems")

      [
        %CurrencyCost{currency_id: _gold_id, amount: gold_cost},
        %CurrencyCost{currency_id: _gems_id, amount: gems_cost}
      ] = Units.calculate_tier_up_cost(unit)

      :ok = SocketTester.tier_up_unit(socket_tester, user.id, unit.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:unit_and_currencies, %UnitAndCurrencies{}}
      }

      fetch_last_message(socket_tester)

      %WebSocketResponse{
        response_type:
          {:unit_and_currencies, %UnitAndCurrencies{unit: unit, user_currency: user_currencies}}
      } = get_last_message()

      user_currencies =
        Enum.into(user_currencies, %{}, fn %UserCurrency{
                                             currency: %Currency{name: name},
                                             amount: amount
                                           } ->
          {name, amount}
        end)

      assert unit.unit_level == 20
      assert unit.tier == 2
      assert user_currencies["Gold"] == user_gold - gold_cost
      assert user_currencies["Gems"] == user_gems - gems_cost

      # TODO: Check that we can now level up

      #### Rank up (fuse)

      {:ok, unit} =
        GameBackend.Units.insert_unit(%{
          user_id: user.id,
          unit_level: 220,
          tier: 8,
          rank: Units.get_rank(:star5),
          selected: false,
          character_id: muflus.id
        })

      rank = unit.rank
      user_units_count = user.id |> Users.get_units() |> Enum.count()

      # Add to-be-consumed units

      {:ok, same_faction_character} =
        GameBackend.Units.Characters.insert_character(%{
          game_id: 2,
          active: true,
          name: "SameFactionUnit",
          faction: muflus.faction,
          rarity: Champions.Units.get_rarity(:rare)
        })

      # We will need three 5* Muflus and two i2 of the same faction
      # For the same faction, we will do one of each unit.
      units_to_consume = create_units_to_consume(user, muflus, same_faction_character)

      # TODO: Check that we cant tier up again without ranking up

      :ok = SocketTester.fuse_unit(socket_tester, user.id, unit.id, units_to_consume)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:unit, %Unit{}}
      }

      fetch_last_message(socket_tester)

      %WebSocketResponse{
        response_type: {:unit, %Unit{} = unit}
      } = get_last_message()

      assert unit.rank == rank + 1
      assert user_units_count == user.id |> Users.get_units() |> Enum.count()
    end

    test "summon", %{socket_tester: socket_tester} do
      {:ok, user} = Users.register("Summon user")
      units = Enum.count(user.units)

      {:ok, previous_scrolls} = Users.add_currency_by_name!(user.id, "Scrolls", 50)
      scrolls = Currencies.get_currency_by_name!("Scrolls")

      [character1, character_2 | _rest] = Characters.get_characters()

      {:ok, box} =
        GameBackend.Gacha.insert_box(%{
          name: "Test Box",
          character_drop_rates: [
            %{character_id: character1.id, weight: 1},
            %{character_id: character_2.id, weight: 1}
          ],
          cost: [%{currency_id: scrolls.id, amount: 50}]
        })

      box = Repo.preload(box, character_drop_rates: :character)

      ### Get boxes
      SocketTester.get_boxes(socket_tester, user.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:boxes, %Boxes{}}
      }

      fetch_last_message(socket_tester)

      %WebSocketResponse{
        response_type: {:boxes, %Boxes{boxes: boxes}}
      } = get_last_message()

      assert box.id in Enum.map(boxes, & &1.id)

      ### Get box

      SocketTester.get_box(socket_tester, box.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:box, %Box{}}
      }

      fetch_last_message(socket_tester)

      %WebSocketResponse{
        response_type: {:box, %Box{id: id, name: name}}
      } = get_last_message()

      assert id == box.id
      assert name == box.name

      ### Pull champion

      SocketTester.pull_box(socket_tester, user.id, box.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:user_and_unit, %UserAndUnit{}}
      }

      fetch_last_message(socket_tester)

      %WebSocketResponse{
        response_type: {:user_and_unit, %UserAndUnit{user: new_user, unit: new_unit}}
      } = get_last_message()

      assert new_unit.character.name in Enum.map(box.character_drop_rates, & &1.character.name)

      new_scrolls = Enum.find(new_user.currencies, &(&1.currency.name == "Scrolls"))
      assert new_scrolls.amount == previous_scrolls.amount - List.first(box.cost).amount

      assert Champions.Users.get_units(user.id) |> Enum.count() == units + 1
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

  defp create_units_to_consume(user, same_character, same_faction),
    do:
      (Enum.map(1..3, fn _ ->
         {:ok, unit} =
           GameBackend.Units.insert_unit(%{
             user_id: user.id,
             unit_level: 100,
             tier: 5,
             rank: Units.get_rank(:star5),
             selected: false,
             character_id: same_character.id
           })

         unit
       end) ++
         [
           GameBackend.Units.insert_unit(%{
             user_id: user.id,
             unit_level: 100,
             tier: 5,
             rank: Units.get_rank(:star5),
             selected: false,
             character_id: same_faction.id
           })
           |> elem(1),
           GameBackend.Units.insert_unit(%{
             user_id: user.id,
             unit_level: 100,
             tier: 5,
             rank: Units.get_rank(:star5),
             selected: false,
             character_id: same_faction.id
           })
           |> elem(1)
         ])
      |> Enum.map(& &1.id)
end
