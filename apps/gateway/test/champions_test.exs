defmodule Gateway.Test.Champions do
  @moduledoc """
  Test for Champions of Mirra messages.
  """
  use ExUnit.Case

  alias Champions.{Units, Users, Utils}
  alias GameBackend.Repo
  alias GameBackend.Users.Currencies.CurrencyCost
  alias GameBackend.Users.Currencies

  alias Gateway.Serialization.{
    Box,
    Boxes,
    Campaign,
    Campaigns,
    Currency,
    Error,
    Level,
    Unit,
    UnitAndCurrencies,
    User,
    UserAndUnit,
    UserCurrency,
    WebSocketResponse
  }

  alias Gateway.SocketTester

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
      username = "Username"

      # Create our user
      :ok = SocketTester.create_user(socket_tester, username)
      fetch_last_message(socket_tester)
      %WebSocketResponse{response_type: {:user, %User{} = user}} = get_last_message()

      assert user.username == username

      # Creating another user with the same name fails
      :ok = SocketTester.create_user(socket_tester, username)
      fetch_last_message(socket_tester)
      assert_receive %WebSocketResponse{response_type: {:error, %Error{reason: "username_taken"}}}

      # Get user by name
      :ok = SocketTester.get_user_by_username(socket_tester, username)
      fetch_last_message(socket_tester)
      assert_receive %WebSocketResponse{response_type: {:user, ^user}}
    end
  end

  describe "units" do
    test "unit selection", %{socket_tester: socket_tester} do
      {:ok, user} = Users.register("SelectUser")

      [unit_to_unselect | _] = user.units
      slot = unit_to_unselect.slot

      # Unit is selected by default (this will change when we remove sample data in user creation)
      assert unit_to_unselect.selected

      # Unselect the unit
      :ok = SocketTester.unselect_unit(socket_tester, user.id, unit_to_unselect.id)
      fetch_last_message(socket_tester)
      %WebSocketResponse{response_type: {:unit, %Unit{} = unselected_unit}} = get_last_message()

      assert not unselected_unit.selected
      # Protobuf doesn't support nil values, returns zero instead
      assert unselected_unit.slot == 0
      assert unselected_unit.id == unit_to_unselect.id

      :ok = SocketTester.select_unit(socket_tester, user.id, unselected_unit.id, slot)
      fetch_last_message(socket_tester)
      %WebSocketResponse{response_type: {:unit, %Unit{} = selected_unit}} = get_last_message()

      assert selected_unit.selected
      assert selected_unit.slot == slot
    end

    test "unit progression", %{socket_tester: socket_tester} do
      muflus = GameBackend.Units.Characters.get_character_by_name("Muflus")
      {:ok, user} = Users.register("LevelUpUser")
      Currencies.add_currency_by_name!(user.id, "Gold", 9999)

      {:ok, unit} =
        GameBackend.Units.insert_unit(%{
          user_id: user.id,
          level: 19,
          tier: 1,
          rank: 2,
          selected: false,
          character_id: muflus.id
        })

      gold = Currencies.get_amount_of_currency_by_name(user.id, "Gold")
      level = unit.level

      #### LevelUpUnit
      [%CurrencyCost{currency_id: _gold_id, amount: level_up_cost}] = Units.calculate_level_up_cost(unit)

      :ok = SocketTester.level_up_unit(socket_tester, user.id, unit.id)
      fetch_last_message(socket_tester)

      %WebSocketResponse{
        response_type: {:unit_and_currencies, %UnitAndCurrencies{unit: unit, user_currency: [user_currency]}}
      } = get_last_message()

      assert unit.level == level + 1
      assert user_currency.currency.name == "Gold"
      assert user_currency.amount == gold - level_up_cost

      # Cannot level up because unit is level 20 with tier 1
      assert unit.level == 20
      assert unit.tier == 1
      :ok = SocketTester.level_up_unit(socket_tester, user.id, unit.id)
      fetch_last_message(socket_tester)
      assert_receive %WebSocketResponse{response_type: {:error, %Error{reason: "cant_level_up"}}}

      #### TierUpUnit

      user_gold = Currencies.get_amount_of_currency_by_name(user.id, "Gold")
      user_gems = Currencies.get_amount_of_currency_by_name(user.id, "Gems")

      [
        %CurrencyCost{currency_id: _gold_id, amount: gold_cost},
        %CurrencyCost{currency_id: _gems_id, amount: gems_cost}
      ] = Units.calculate_tier_up_cost(unit)

      :ok = SocketTester.tier_up_unit(socket_tester, user.id, unit.id)
      fetch_last_message(socket_tester)

      %WebSocketResponse{
        response_type: {:unit_and_currencies, %UnitAndCurrencies{unit: unit, user_currency: user_currencies}}
      } = get_last_message()

      user_currencies =
        Enum.into(user_currencies, %{}, fn %UserCurrency{
                                             currency: %Currency{name: name},
                                             amount: amount
                                           } ->
          {name, amount}
        end)

      assert unit.level == 20
      assert unit.tier == 2
      assert user_currencies["Gold"] == user_gold - gold_cost
      assert user_currencies["Gems"] == user_gems - gems_cost

      # Check that we can now LevelUpUnit
      :ok = SocketTester.level_up_unit(socket_tester, user.id, unit.id)
      fetch_last_message(socket_tester)

      %WebSocketResponse{
        response_type: {:unit_and_currencies, %UnitAndCurrencies{unit: unit}}
      } = get_last_message()

      assert unit.level == level + 2

      #### Rank up (FuseUnit)

      {:ok, unit} =
        GameBackend.Units.insert_unit(%{
          user_id: user.id,
          level: 100,
          tier: 5,
          rank: Units.get_rank(:star5),
          selected: false,
          character_id: muflus.id
        })

      unit = Repo.preload(unit, [:character])

      rank = unit.rank
      user_units_count = user.id |> GameBackend.Units.get_units() |> Enum.count()

      # Add to-be-consumed units

      {:ok, same_faction_character} =
        GameBackend.Units.Characters.insert_character(%{
          game_id: Utils.game_id(),
          active: true,
          name: "SameFactionUnit",
          faction: muflus.faction,
          quality: Champions.Units.get_quality(:rare)
        })

      # We will need three 5* Muflus and two i2 of the same faction
      # For the same faction, we will do one of each unit.
      units_to_consume = create_units_to_consume(user, muflus, same_faction_character)

      # Characters need a certain quality to rank up
      assert unit.character.quality == Units.get_quality(:epic)

      # Check that we cant TierUpUnit again without ranking up
      :ok = SocketTester.tier_up_unit(socket_tester, user.id, unit.id)
      fetch_last_message(socket_tester)

      %WebSocketResponse{
        response_type: {:error, %Error{reason: "cant_tier_up"}}
      } = get_last_message()

      # FuseUnit
      :ok = SocketTester.fuse_unit(socket_tester, user.id, unit.id, units_to_consume)
      fetch_last_message(socket_tester)

      %WebSocketResponse{
        response_type: {:unit, %Unit{} = unit}
      } = get_last_message()

      assert unit.rank == rank + 1
      assert user_units_count == user.id |> GameBackend.Units.get_units() |> Enum.count()
    end

    test "summon", %{socket_tester: socket_tester} do
      {:ok, user} = Users.register("Summon user")
      units = Enum.count(user.units)

      {:ok, previous_scrolls} = Currencies.add_currency_by_name!(user.id, "Summon Scrolls", 1)

      {:ok, box} = GameBackend.Gacha.get_box_by_name("Basic Summon")

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
        response_type: {:box, %Box{id: box_id, name: box_name}}
      } = get_last_message()

      assert box_id == box.id
      assert box_name == box.name

      ### Pull champion

      SocketTester.summon(socket_tester, user.id, box_id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:user_and_unit, %UserAndUnit{}}
      }

      fetch_last_message(socket_tester)

      %WebSocketResponse{
        response_type: {:user_and_unit, %UserAndUnit{user: new_user, unit: new_unit}}
      } = get_last_message()

      assert new_unit.rank in Enum.map(box.rank_weights, & &1.rank)

      new_scrolls = Enum.find(new_user.currencies, &(&1.currency.name == "Summon Scrolls"))
      assert new_scrolls.amount == previous_scrolls.amount - List.first(box.cost).amount

      assert GameBackend.Units.get_units(user.id) |> Enum.count() == units + 1
    end
  end

  describe "campaigns" do
    test "get campaigns and levels", %{socket_tester: socket_tester} do
      # Register user
      {:ok, user} = Users.register("campaign_user")

      # GetCampaigns
      SocketTester.get_campaigns(socket_tester, user.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:campaigns, %Campaigns{} = campaigns}
      }

      assert Enum.count(campaigns.campaigns) > 0

      sample_campaign = Enum.random(campaigns.campaigns)

      # GetCampaign
      SocketTester.get_campaign(socket_tester, user.id, sample_campaign.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:campaign, %Campaign{}}
      }

      fetch_last_message(socket_tester)

      %WebSocketResponse{
        response_type: {:campaign, %Campaign{} = campaign_to_verify}
      } =
        get_last_message()

      assert campaign_to_verify.id == sample_campaign.id

      # GetLevel
      level = Enum.random(sample_campaign.levels)

      SocketTester.get_level(socket_tester, user.id, level.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:level, %Level{}}
      }

      fetch_last_message(socket_tester)

      %WebSocketResponse{
        response_type: {:level, %Level{} = level_to_verify}
      } = get_last_message()

      assert level_to_verify.id == level.id
    end

    test "fight level", %{socket_tester: socket_tester} do
      # Register user
      {:ok, user} = Users.register("battle_user")

      # Get user's first campaign progression
      [campaign_progression | _] = user.campaign_progress

      # Get the level of the campaign progression
      level_id = campaign_progression.level_id

      # FightLevel
      SocketTester.fight_level(socket_tester, user.id, level_id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:battle_result, _}
      }

      fetch_last_message(socket_tester)

      %WebSocketResponse{
        response_type: {:battle_result, _ = battle_result}
      } = get_last_message()

      # Battle result should be either win or loss
      assert battle_result.result == "win" or battle_result.result == "loss"

      # TODO: check rewards [#CHoM-341]
    end

    test "fight level advances level in the campaign progression", %{socket_tester: socket_tester} do
      # Register user
      {:ok, user} = Users.register("battle_winning_user")

      # Make user units very strong to win the battle
      Enum.each(user.units, fn unit ->
        GameBackend.Units.update_unit(unit, %{level: 9999})
      end)

      # Get user's first campaign progression
      [campaign_progression | _] = user.campaign_progress

      # Get the level of the campaign progression
      level_id = campaign_progression.level_id

      # FightLevel
      SocketTester.fight_level(socket_tester, user.id, level_id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:battle_result, _}
      }

      fetch_last_message(socket_tester)

      %WebSocketResponse{
        response_type: {:battle_result, _ = battle_result}
      } = get_last_message()

      assert battle_result.result == "win"

      {:ok, advanced_user} = Users.get_user(user.id)

      IO.inspect(advanced_user, label: "advanced_user")

      [advanced_campaign_progression | _] = advanced_user.campaign_progress

      assert user.id == advanced_user.id
      assert advanced_campaign_progression.level_id != level_id
    end

    test "can not fight a level that is not the next level in the progression", %{socket_tester: socket_tester} do
      # Register user
      {:ok, user} = Users.register("invalid_battle_user")

      # Get user's first campaign progression
      [campaign_progression | _] = user.campaign_progress

      # Get the level of the campaign progression
      next_level_id = campaign_progression.level_id

      # Get a level from the user where the id is not the next level in the progression
      SocketTester.get_campaigns(socket_tester, user.id)
      fetch_last_message(socket_tester)

      %WebSocketResponse{
        response_type: {:campaigns, %Campaigns{} = campaigns}
      } = get_last_message()

      levels = Enum.map(campaigns.campaigns, & &1.levels) |> List.flatten()
      invalid_level = Enum.find(levels, fn level -> level.id != next_level_id end)

      # FightLevel
      SocketTester.fight_level(socket_tester, user.id, invalid_level.id)
      fetch_last_message(socket_tester)

      # Should return an error response with the reason "level_invalid"
      assert_receive %WebSocketResponse{
        response_type: {:error, %Error{reason: "level_invalid"}}
      }
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
    :timer.sleep(100)
    send(socket_tester, {:last_message, self()})
  end

  defp create_units_to_consume(user, same_character, same_faction) do
    params = %{
      user_id: user.id,
      level: 100,
      tier: 5,
      rank: Units.get_rank(:star5),
      selected: false
    }

    same_character_ids =
      Enum.map(1..3, fn _ ->
        {:ok, unit} = params |> Map.put(:character_id, same_character.id) |> GameBackend.Units.insert_unit()
        unit.id
      end)

    same_faction_ids =
      Enum.map(1..2, fn _ ->
        {:ok, unit} = params |> Map.put(:character_id, same_faction.id) |> GameBackend.Units.insert_unit()
        unit.id
      end)

    same_character_ids ++ same_faction_ids
  end
end
