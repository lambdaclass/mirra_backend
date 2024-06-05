defmodule Gateway.Test.Champions do
  @moduledoc """
  Test for Champions of Mirra messages.
  """
  import Ecto.Query

  use ExUnit.Case

  alias Champions.{Units, Users}
  alias GameBackend.Campaigns.Rewards.AfkRewardRate
  alias GameBackend.Items
  alias GameBackend.Repo
  alias GameBackend.Units.Unit
  alias GameBackend.Users.Currencies
  alias GameBackend.Users.Currencies.CurrencyCost
  alias GameBackend.Utils

  alias Gateway.Serialization.{
    Box,
    Boxes,
    Campaign,
    Campaigns,
    Currency,
    Error,
    Item,
    Level,
    Unit,
    UnitAndCurrencies,
    User,
    UserAndUnit,
    UserCurrency,
    WebSocketResponse
  }

  alias Gateway.SocketTester

  setup do
    {:ok, socket_tester} = SocketTester.start_link()

    {:ok, %{socket_tester: socket_tester}}
  end

  describe "users" do
    test "users", %{socket_tester: socket_tester} do
      username = "Username"

      # CreateUser
      :ok = SocketTester.create_user(socket_tester, username)
      fetch_last_message(socket_tester)
      assert_receive %WebSocketResponse{response_type: {:user, %User{} = user}}

      assert user.username == username

      # CreateUser with the same username fails
      :ok = SocketTester.create_user(socket_tester, username)
      fetch_last_message(socket_tester)
      assert_receive %WebSocketResponse{response_type: {:error, %Error{reason: "username_taken"}}}

      # GetUserByUsername
      :ok = SocketTester.get_user_by_username(socket_tester, username)
      fetch_last_message(socket_tester)
      assert_receive %WebSocketResponse{response_type: {:user, ^user}}

      # GetUser
      :ok = SocketTester.get_user(socket_tester, user.id)
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
      assert_receive %WebSocketResponse{response_type: {:unit, %Unit{} = unselected_unit}}

      assert not unselected_unit.selected
      # Protobuf doesn't support nil values, returns zero instead
      assert unselected_unit.slot == 0
      assert unselected_unit.id == unit_to_unselect.id

      :ok = SocketTester.select_unit(socket_tester, user.id, unselected_unit.id, slot)
      fetch_last_message(socket_tester)
      assert_receive %WebSocketResponse{response_type: {:unit, %Unit{} = selected_unit}}

      assert selected_unit.selected
      assert selected_unit.slot == slot
    end

    test "progression", %{socket_tester: socket_tester} do
      muflus = GameBackend.Units.Characters.get_character_by_name("Muflus")
      {:ok, user} = Users.register("LevelUpUser")
      Currencies.add_currency_by_name_and_game!(user.id, "Gold", Utils.get_game_id(:champions_of_mirra), 9999)

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

      assert_receive %WebSocketResponse{
        response_type: {:unit_and_currencies, %UnitAndCurrencies{unit: unit, user_currency: [user_currency]}}
      }

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

      assert_receive %WebSocketResponse{
        response_type: {:unit_and_currencies, %UnitAndCurrencies{unit: unit, user_currency: user_currencies}}
      }

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

      assert_receive %WebSocketResponse{
        response_type: {:unit_and_currencies, %UnitAndCurrencies{unit: unit}}
      }

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
          game_id: Utils.get_game_id(:champions_of_mirra),
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

      assert_receive %WebSocketResponse{
        response_type: {:error, %Error{reason: "cant_tier_up"}}
      }

      # FuseUnit
      :ok = SocketTester.fuse_unit(socket_tester, user.id, unit.id, units_to_consume)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:unit, %Unit{} = unit}
      }

      assert unit.rank == rank + 1
      assert user_units_count == user.id |> GameBackend.Units.get_units() |> Enum.count()
    end

    test "summon", %{socket_tester: socket_tester} do
      {:ok, user} = Users.register("Summon user")
      units = Enum.count(user.units)

      {:ok, previous_scrolls} =
        Currencies.add_currency_by_name_and_game!(user.id, "Summon Scrolls", Utils.get_game_id(:champions_of_mirra), 1)

      {:ok, box} = GameBackend.Gacha.get_box_by_name("Basic Summon")

      ### Get boxes
      SocketTester.get_boxes(socket_tester, user.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:boxes, %Boxes{boxes: boxes}}
      }

      assert box.id in Enum.map(boxes, & &1.id)

      ### Get box

      SocketTester.get_box(socket_tester, box.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:box, %Box{id: box_id, name: box_name}}
      }

      assert box_id == box.id
      assert box_name == box.name

      ### Pull champion

      SocketTester.summon(socket_tester, user.id, box_id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:user_and_unit, %UserAndUnit{user: new_user, unit: new_unit}}
      }

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

      repo_campaigns = Repo.all(GameBackend.Campaigns.Campaign)

      # Check that each campaign matches a campaign of repo_campaigns
      assert :ok ==
               Enum.each(campaigns.campaigns, fn campaign ->
                 assert Enum.find(repo_campaigns, &(&1.id == campaign.id))
               end)

      sample_campaign = Enum.random(campaigns.campaigns)

      # GetCampaign
      SocketTester.get_campaign(socket_tester, user.id, sample_campaign.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:campaign, %Campaign{} = campaign_to_verify}
      }

      assert campaign_to_verify.id == sample_campaign.id

      # GetLevel
      level = Enum.random(sample_campaign.levels)

      SocketTester.get_level(socket_tester, user.id, level.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:level, %Level{} = level_to_verify}
      }

      assert level_to_verify.id == level.id
    end

    test "fight level", %{socket_tester: socket_tester} do
      # Register user
      {:ok, user} = Users.register("battle_user")

      # Get user's Main Campaign progress
      main_super_campaign =
        GameBackend.Campaigns.get_super_campaign_by_name_and_game(
          "Main Campaign",
          Utils.get_game_id(:champions_of_mirra)
        )

      {:ok, super_campaign_progress} =
        GameBackend.Campaigns.get_super_campaign_progress(user.id, main_super_campaign.id)

      # Get the SuperCampaignProgress' Level
      level_id = super_campaign_progress.level_id

      # FightLevel
      SocketTester.fight_level(socket_tester, user.id, level_id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:battle_result, battle_result}
      }

      # Battle result should be either team_1, team_2, draw or timeout
      assert battle_result.result in ["team_1", "team_2", "draw", "timeout"]

      # TODO: check rewards [#CHoM-341]
    end

    test "fight level advances level in the SuperCampaignProgress", %{socket_tester: socket_tester} do
      # Register user
      {:ok, user} = Users.register("battle_winning_user")

      # Make user units very strong to win the battle
      Enum.each(user.units, fn unit ->
        GameBackend.Units.update_unit(unit, %{level: 9999})
      end)

      # Get user's progress in the main SuperCampaign
      main_super_campaign =
        GameBackend.Campaigns.get_super_campaign_by_name_and_game(
          "Main Campaign",
          Utils.get_game_id(:champions_of_mirra)
        )

      {:ok, super_campaign_progress} =
        GameBackend.Campaigns.get_super_campaign_progress(user.id, main_super_campaign.id)

      # Get the SuperCampaignProgress' Level
      level_id = super_campaign_progress.level_id
      level_number = super_campaign_progress.level.level_number

      # FightLevel
      SocketTester.fight_level(socket_tester, user.id, level_id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:battle_result, _ = battle_result}
      }

      assert battle_result.result == "team_1"

      {:ok, advanced_user} = Users.get_user(user.id)

      {:ok, advanced_super_campaign_progress} =
        GameBackend.Campaigns.get_super_campaign_progress(user.id, main_super_campaign.id)

      assert user.id == advanced_user.id
      assert advanced_super_campaign_progress.level_id != level_id
      assert advanced_super_campaign_progress.level.level_number == level_number + 1
    end

    test "can not fight a Level that is not the next one in the SuperCampaignProgress", %{
      socket_tester: socket_tester
    } do
      # Register user
      {:ok, user} = Users.register("invalid_battle_user")

      # Get user's Main Campaign progress
      main_super_campaign =
        GameBackend.Campaigns.get_super_campaign_by_name_and_game(
          "Main Campaign",
          Utils.get_game_id(:champions_of_mirra)
        )

      {:ok, super_campaign_progress} =
        GameBackend.Campaigns.get_super_campaign_progress(user.id, main_super_campaign.id)

      next_level_id = super_campaign_progress.level_id

      # Get a Level that is not the next one in the SuperCampaignProgress
      SocketTester.get_campaigns(socket_tester, user.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:campaigns, %Campaigns{} = campaigns}
      }

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

  describe "items" do
    test "get item", %{socket_tester: socket_tester} do
      {:ok, user} = Users.register("GetItemUser")

      {:ok, epic_bow} =
        Items.insert_item_template(%{
          game_id: Utils.get_game_id(:champions_of_mirra),
          name: "Epic Bow of Testness",
          config_id: "epic_bow_of_testness",
          type: "weapon",
          rarity: 1,
          modifiers: [
            %{
              attribute: "attack",
              operation: "Multiply",
              value: 1.6
            }
          ]
        })

      {:ok, item} = Items.insert_item(%{user_id: user.id, template_id: epic_bow.id, level: 1})

      :ok = SocketTester.get_item(socket_tester, user.id, item.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:item, %Item{} = fetched_item}
      }

      assert fetched_item.id == item.id
      assert fetched_item.user_id == user.id
      assert fetched_item.template.id == epic_bow.id

      # We expect the item to be unequipped after creation. Since protobuf can't handle null messages, we get an empty string.
      assert fetched_item.unit_id == ""
    end

    test "equip and unequip item", %{socket_tester: socket_tester} do
      # Register user
      {:ok, user} = Users.register("EquipItemUser")

      [unit | _] = user.units

      attack_multiplier = 1.6
      defense_multiplier = 1.2
      health_adder = 100

      {:ok, epic_item} =
        Items.insert_item_template(%{
          game_id: Utils.get_game_id(:champions_of_mirra),
          name: "Epic Upgrader of All Stats",
          config_id: "epic_upgrader_of_all_stats",
          type: "weapon",
          rarity: 1,
          modifiers: [
            %{
              attribute: "attack",
              operation: "Multiply",
              value: attack_multiplier
            },
            %{
              attribute: "defense",
              operation: "Multiply",
              value: defense_multiplier
            },
            %{
              attribute: "health",
              operation: "Add",
              value: health_adder
            }
          ]
        })

      {:ok, item} = Items.insert_item(%{user_id: user.id, template_id: epic_item.id, level: 1})

      # EquipItem
      attack_before_equip = Units.get_attack(unit)
      defense_before_equip = Units.get_defense(unit)
      health_before_equip = Units.get_health(unit)

      :ok = SocketTester.equip_item(socket_tester, user.id, item.id, unit.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:item, %Item{} = equipped_item}
      }

      # The item is now equipped to the unit
      assert equipped_item.user_id == user.id
      assert equipped_item.unit_id == unit.id

      # The item affected the unit stats
      {:ok, updated_user} = Users.get_user(user.id)

      unit_with_item =
        updated_user.units
        |> Enum.filter(&(&1.id == unit.id))
        |> hd()
        |> Repo.preload(items: :template)

      # We use a range to avoid floating point rounding/truncating errors
      assert Units.get_attack(unit_with_item) in trunc(attack_multiplier * attack_before_equip * 0.95)..trunc(
               attack_multiplier *
                 attack_before_equip * 1.05
             )

      assert Units.get_defense(unit_with_item) in trunc(defense_multiplier * defense_before_equip * 0.95)..trunc(
               defense_multiplier *
                 defense_before_equip * 1.05
             )

      assert Units.get_health(unit_with_item) == health_before_equip + health_adder

      # EquipItem again, to another unit
      another_unit = user.units |> Enum.at(1)
      :ok = SocketTester.equip_item(socket_tester, user.id, item.id, another_unit.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:item, %Item{} = equipped_item}
      }

      # The item is now equipped to the second unit
      assert equipped_item.user_id == user.id
      assert equipped_item.unit_id != unit.id
      assert equipped_item.unit_id == another_unit.id

      # UnequipItem
      :ok = SocketTester.unequip_item(socket_tester, user.id, item.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:item, %Item{} = unequipped_item}
      }

      # The item is now unequipped
      assert unequipped_item.user_id == user.id
      assert unequipped_item.unit_id == ""

      # The unit stats are back to normal
      {:ok, updated_user} = Users.get_user(user.id)

      unit_without_item =
        updated_user.units
        |> Enum.filter(&(&1.id == unit.id))
        |> hd()
        |> Repo.preload(items: :template)

      assert Units.get_attack(unit_without_item) == attack_before_equip
      assert Units.get_defense(unit_without_item) == defense_before_equip
      assert Units.get_health(unit_without_item) == health_before_equip
    end

    test "tier up item", %{socket_tester: socket_tester} do
      # Register user
      {:ok, user} = Users.register("LevelUpItemUser")

      gold_upgrade_cost = 100

      {:ok, epic_axe_tier_1} =
        Items.insert_item_template(%{
          game_id: Utils.get_game_id(:champions_of_mirra),
          name: "Epic Axe of Testness",
          config_id: "epic_axe_of_testness_t1",
          type: "weapon",
          rarity: 1,
          tier: 1,
          modifiers: [
            %{
              attribute: "attack",
              operation: "Multiply",
              value: 1.6
            }
          ]
        })

      {:ok, epic_axe_tier_2} =
        Items.insert_item_template(%{
          game_id: GameBackend.Utils.get_game_id(:champions_of_mirra),
          name: "Epic Axe of Testness",
          config_id: "epic_axe_of_testness_t2",
          upgrades_from_config_id: "epic_axe_of_testness_t1",
          upgrade_costs: [
            %{
              currency_id: Currencies.get_currency_by_name_and_game!("Gold", Utils.get_game_id(:champions_of_mirra)).id,
              amount: gold_upgrade_cost
            }
          ],
          upgrades_from_quantity: 3,
          type: "weapon",
          rarity: 1,
          tier: 2,
          modifiers: [
            %{
              attribute: "attack",
              operation: "Multiply",
              value: 2
            }
          ]
        })

      {:ok, item_1} = Items.insert_item(%{user_id: user.id, template_id: epic_axe_tier_1.id})
      {:ok, item_2} = Items.insert_item(%{user_id: user.id, template_id: epic_axe_tier_1.id})
      {:ok, item_3} = Items.insert_item(%{user_id: user.id, template_id: epic_axe_tier_1.id})

      # Add required gold amount to user
      Currencies.add_currency(
        user.id,
        Currencies.get_currency_by_name_and_game!("Gold", Utils.get_game_id(:champions_of_mirra)).id,
        gold_upgrade_cost
      )

      gold_amount_before_level_up = Currencies.get_amount_of_currency_by_name(user.id, "Gold")

      # FuseItems
      :ok = SocketTester.fuse_items(socket_tester, user.id, [item_1.id, item_2.id, item_3.id])
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:item, %Item{} = new_item}
      }

      assert new_item.template.id == epic_axe_tier_2.id
      assert new_item.template.config_id == epic_axe_tier_2.config_id
      assert new_item.user_id == user.id
      assert new_item.unit_id == ""

      assert Currencies.get_amount_of_currency_by_name(user.id, "Gold") ==
               gold_amount_before_level_up - gold_upgrade_cost

      # Try to Fuse the new item with nothing else and it will fail
      :ok = SocketTester.fuse_items(socket_tester, user.id, [new_item.id])
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{response_type: {:error, %Error{reason: "consumed_items_invalid"}}}
    end
  end

  describe "kaline tree" do
    test "kaline tree", %{socket_tester: socket_tester} do
      {:ok, user} = Users.register("KalineTreeUser")

      # Kaline tree level is 1 when the user is created.
      initial_kaline_tree_level = user.kaline_tree_level.level
      assert initial_kaline_tree_level == 1

      initial_fertilizer = Currencies.get_amount_of_currency_by_name(user.id, "Fertilizer")
      initial_gold = Currencies.get_amount_of_currency_by_name(user.id, "Gold")

      # Level up Kaline Tree with enough fertilizer should return an updated user.
      SocketTester.level_up_kaline_tree(socket_tester, user.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{response_type: {:user, %User{} = leveled_up_user}}
      assert leveled_up_user.kaline_tree_level.level == initial_kaline_tree_level + 1

      # Currency should be deducted
      assert Currencies.get_amount_of_currency_by_name(user.id, "Fertilizer") ==
               initial_fertilizer - user.kaline_tree_level.fertilizer_level_up_cost

      assert Currencies.get_amount_of_currency_by_name(user.id, "Gold") ==
               initial_gold - user.kaline_tree_level.gold_level_up_cost

      # Level up Kaline Tree without enough fertilizer should return an error.
      SocketTester.level_up_kaline_tree(socket_tester, user.id)

      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{response_type: {:error, %Error{reason: "cant_afford"}}}
    end

    test "leveling up the Kaline Tree increments the afk rewards", %{socket_tester: socket_tester} do
      {:ok, user} = Users.register("KalineTreeAFKRewardsUser")

      # Check that the initial afk reward rates is not an empty list
      assert Enum.any?(user.kaline_tree_level.afk_reward_rates)

      # Check that the gold, arcane crystals and hero souls afk rewards rates are 0 initially
      rewardable_currencies = ["Gold", "Hero Souls", "Arcane Crystals"]

      assert Enum.all?(user.kaline_tree_level.afk_reward_rates, fn rate ->
               case rate.currency.name in rewardable_currencies do
                 true ->
                   rate.rate == 0

                 false ->
                   rate.rate == 0
               end
             end)

      # Level up the Kaline Tree
      SocketTester.level_up_kaline_tree(socket_tester, user.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{response_type: {:user, %User{} = leveled_up_user}}

      # Check that any afk reward rates exist
      assert Enum.any?(leveled_up_user.kaline_tree_level.afk_reward_rates)

      # Check that the gold, arcane crystals and hero souls afk rewards rates are greater than 0
      assert Enum.all?(leveled_up_user.kaline_tree_level.afk_reward_rates, fn rate ->
               case rate.currency.name in rewardable_currencies do
                 true ->
                   rate.rate > 0

                 false ->
                   rate.rate == 0
               end
             end)

      # Claim afk rewards
      currencies_before_claiming = leveled_up_user.currencies

      # Simulate waiting 2 seconds before claiming the rewards, to let the rewards accumulate
      seconds_to_wait = 2
      {:ok, leveled_up_user_with_rewards} = Users.get_user(leveled_up_user.id)

      {:ok, _} =
        leveled_up_user_with_rewards
        |> GameBackend.Users.User.changeset(%{
          last_kaline_afk_reward_claim: DateTime.utc_now() |> DateTime.add(-seconds_to_wait, :second)
        })
        |> Repo.update()

      SocketTester.claim_kaline_afk_rewards(socket_tester, leveled_up_user.id)
      fetch_last_message(socket_tester)
      assert_receive %WebSocketResponse{response_type: {:user, %User{} = claimed_user}}

      # Check that the user has received gold, arcane crystals and hero souls
      # The amount should be greater than the initial amount and be in the range of the expected amount considering the time waited.
      # We add 10% to the time waited to account for the time it takes to process the message.
      assert Enum.all?(claimed_user.currencies, fn currency ->
               user_currency = Enum.find(claimed_user.currencies, &(&1.currency.name == currency.currency.name))

               case Enum.find(
                      claimed_user.kaline_tree_level.afk_reward_rates,
                      &(&1.currency.name == currency.currency.name)
                    ) do
                 nil ->
                   # If the currency is not in the afk rewards rates, we don't consider it.
                   true

                 rate ->
                   reward_rate = rate.rate

                   currency_before_claim =
                     Enum.find(currencies_before_claiming, &(&1.currency.name == currency.currency.name)).amount

                   expected_amount = trunc(currency_before_claim + reward_rate * seconds_to_wait)
                   user_currency.amount in expected_amount..trunc(expected_amount * 1.1)
               end
             end)

      # TODO: check that the afk rewards rates have been reset after [CHoM-380] is solved (https://github.com/lambdaclass/mirra_backend/issues/385)

      # Level up the Kaline Tree again to check that the afk rewards rates have increased
      Currencies.add_currency_by_name_and_game!(claimed_user.id, "Gold", Utils.get_game_id(:champions_of_mirra), 200)

      Currencies.add_currency_by_name_and_game!(
        claimed_user.id,
        "Fertilizer",
        Utils.get_game_id(:champions_of_mirra),
        200
      )

      SocketTester.level_up_kaline_tree(socket_tester, claimed_user.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{response_type: {:user, %User{} = more_advanced_user}}
      current_kaline_tree_level_id = more_advanced_user.kaline_tree_level.id

      current_level_afk_rewards_rates =
        Repo.all(from(r in AfkRewardRate, where: r.kaline_tree_level_id == ^current_kaline_tree_level_id))
        |> Repo.preload(:currency)

      assert Enum.all?(more_advanced_user.kaline_tree_level.afk_reward_rates, fn rate ->
               case rate.currency.name in rewardable_currencies do
                 true ->
                   previous_rate =
                     Enum.find(
                       leveled_up_user.kaline_tree_level.afk_reward_rates,
                       &(&1.currency.name == rate.currency.name)
                     ).rate

                   afk_reward_rate =
                     Enum.find(current_level_afk_rewards_rates, &(&1.currency.name == rate.currency.name)).rate

                   new_rate = previous_rate + afk_reward_rate
                   rate.rate > previous_rate

                 false ->
                   rate.rate == 0
               end
             end)
    end
  end

  describe "Dungeon Settlement" do
    test "Dungeon Settlement", %{socket_tester: socket_tester} do
      {:ok, user} = Users.register("Dungeon Settlement User")

      # Dungeon Settlement level is 1 when the user is created.
      initial_dungeon_settlement_level = user.dungeon_settlement_level.level
      assert initial_dungeon_settlement_level == 1

      initial_blueprints = Currencies.get_amount_of_currency_by_name(user.id, "Blueprints")
      initial_gold = Currencies.get_amount_of_currency_by_name(user.id, "Gold")

      # Due to sample currencies
      assert initial_blueprints == 50
      assert initial_gold == 100
      initial_currencies = %{"Blueprints" => initial_blueprints, "Gold" => initial_gold}

      # Level up Dungeon Settlements with enough Blueprints and Gold should return an updated user.
      SocketTester.level_up_dungeon_settlement(socket_tester, user.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{response_type: {:user, %User{} = leveled_up_user}}
      assert leveled_up_user.dungeon_settlement_level.level == initial_dungeon_settlement_level + 1

      # Currency should be deducted
      Enum.each(user.dungeon_settlement_level.level_up_costs, fn currency_cost ->
        assert Currencies.get_amount_of_currency_by_name(user.id, currency_cost.currency.name) ==
                 (Map.get(initial_currencies, currency_cost.currency.name) - currency_cost.amount) |> max(0)
      end)

      # Level up Dungeon Settlements without enough blueprints should return an error.
      SocketTester.level_up_dungeon_settlement(socket_tester, user.id)

      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{response_type: {:error, %Error{reason: "cant_afford"}}}
    end

    test "leveling up the Dungeon Settlements increments the afk rewards", %{socket_tester: socket_tester} do
      {:ok, user} = Users.register("DungeonSettlementAFKRewardsUser")

      # Check that the initial afk reward rates is not an empty list
      assert Enum.any?(user.dungeon_settlement_level.afk_reward_rates)

      # Check that supply afk reward rates are 0 initially
      rewardable_currencies = ["Supplies"]

      assert Enum.all?(user.dungeon_settlement_level.afk_reward_rates, fn rate ->
               case rate.currency.name in rewardable_currencies do
                 true ->
                   rate.rate == 0

                 false ->
                   rate.rate == 0
               end
             end)

      # Add enough blueprints for 1 upgrade
      {:ok, _} =
        Currencies.add_currency_by_name_and_game!(user.id, "Blueprints", Utils.get_game_id(:champions_of_mirra), 50)

      # Level up the Dungeon Settlement
      SocketTester.level_up_dungeon_settlement(socket_tester, user.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{response_type: {:user, %User{} = leveled_up_user}}

      # Check that any afk reward rates exist
      assert Enum.any?(leveled_up_user.dungeon_settlement_level.afk_reward_rates)

      # Check that supply afk reward rate is greater than 0
      assert Enum.all?(leveled_up_user.dungeon_settlement_level.afk_reward_rates, fn rate ->
               case rate.currency.name in rewardable_currencies do
                 true ->
                   rate.rate > 0

                 false ->
                   rate.rate == 0
               end
             end)

      # Claim afk rewards
      currencies_before_claiming = leveled_up_user.currencies

      # Simulate waiting 2 seconds before claiming the rewards, to let the rewards accumulate
      seconds_to_wait = 2
      {:ok, leveled_up_user_with_rewards} = Users.get_user(leveled_up_user.id)

      {:ok, _} =
        leveled_up_user_with_rewards
        |> GameBackend.Users.User.changeset(%{
          last_dungeon_afk_reward_claim: DateTime.utc_now() |> DateTime.add(-seconds_to_wait, :second)
        })
        |> Repo.update()

      SocketTester.claim_dungeon_afk_rewards(socket_tester, leveled_up_user.id)
      fetch_last_message(socket_tester)
      assert_receive %WebSocketResponse{response_type: {:user, %User{} = claimed_user}}

      # Check that the user has received supplies
      # The amount should be greater than the initial amount and be in the range of the expected amount considering the time waited.
      # We add 10% to the time waited to account for the time it takes to process the message.
      assert Enum.all?(claimed_user.currencies, fn currency ->
               user_currency = Enum.find(claimed_user.currencies, &(&1.currency.name == currency.currency.name))

               case Enum.find(
                      claimed_user.dungeon_settlement_level.afk_reward_rates,
                      &(&1.currency.name == currency.currency.name)
                    ) do
                 nil ->
                   # If the currency is not in the afk rewards rates, we don't consider it.
                   true

                 rate ->
                   reward_rate = rate.rate

                   currency_before_claim =
                     Enum.find(currencies_before_claiming, &(&1.currency.name == currency.currency.name)).amount

                   expected_amount = trunc(currency_before_claim + reward_rate * seconds_to_wait)
                   # Note: This will fail if the initial amount for a user exceeds the UserCurrencyCap
                   user_currency.amount in expected_amount..trunc(expected_amount * 1.1)
               end
             end)

      # TODO: check that the afk rewards rates have been reset after [CHoM-380] is solved (https://github.com/lambdaclass/mirra_backend/issues/385)

      # Level up the Dungeon Settlements again to check that the afk rewards rates have increased
      {:ok, _} =
        Currencies.add_currency_by_name_and_game!(claimed_user.id, "Gold", Utils.get_game_id(:champions_of_mirra), 200)

      {:ok, _} =
        Currencies.add_currency_by_name_and_game!(
          claimed_user.id,
          "Blueprints",
          Utils.get_game_id(:champions_of_mirra),
          200
        )

      SocketTester.level_up_dungeon_settlement(socket_tester, claimed_user.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{response_type: {:user, %User{} = more_advanced_user}}
      current_dungeon_settlement_level_id = more_advanced_user.dungeon_settlement_level.id

      current_level_afk_rewards_rates =
        Repo.all(from(r in AfkRewardRate, where: r.dungeon_settlement_level_id == ^current_dungeon_settlement_level_id))
        |> Repo.preload(:currency)

      assert Enum.all?(more_advanced_user.dungeon_settlement_level.afk_reward_rates, fn rate ->
               case rate.currency.name in rewardable_currencies do
                 true ->
                   previous_rate =
                     Enum.find(
                       leveled_up_user.dungeon_settlement_level.afk_reward_rates,
                       &(&1.currency.name == rate.currency.name)
                     ).rate

                   afk_reward_rate =
                     Enum.find(current_level_afk_rewards_rates, &(&1.currency.name == rate.currency.name)).rate

                   new_rate = previous_rate + afk_reward_rate
                   rate.rate > previous_rate

                 false ->
                   rate.rate == 0
               end
             end)

      # Check that supply cap works
      # We give the an amount that is sure to reach the cap
      {:ok, %Currencies.UserCurrency{} = user_currency} =
        Currencies.add_currency_by_name_and_game!(
          more_advanced_user.id,
          "Supplies",
          Utils.get_game_id(:champions_of_mirra),
          Currencies.get_user_currency_cap(
            more_advanced_user.id,
            Currencies.get_currency_by_name_and_game!("Supplies", Utils.get_game_id(:champions_of_mirra)).id
          )
        )

      # If we claim the rewards, the amount should not change, as it has reached the cap
      SocketTester.claim_dungeon_afk_rewards(socket_tester, more_advanced_user.id)
      fetch_last_message(socket_tester)
      assert_receive %WebSocketResponse{response_type: {:user, %User{} = capped_user}}
      assert Enum.find(capped_user.currencies, &(&1.currency.name == "Supplies")).amount == user_currency.amount
    end
  end

  describe "Dungeon Settlement Upgrades" do
    test "Dungeon Settlement Upgrades", %{socket_tester: socket_tester} do
      {:ok, user} = Users.register("Dungeon Settlement Upgrades User")

      {:ok, hp_upgrade_1} = GameBackend.Users.get_upgrade_by_name("Dungeon.HPUpgrade1")
      {:ok, _hp_upgrade_2} = GameBackend.Users.get_upgrade_by_name("Dungeon.HPUpgrade2")

      dungeon_campaign =
        GameBackend.Campaigns.get_super_campaign_by_name_and_game("Dungeon", Utils.get_game_id(:champions_of_mirra))

      {:ok, dungeon_campaign_progress} =
        GameBackend.Campaigns.get_super_campaign_progress(user.id, dungeon_campaign.id)

      dungeon_level = dungeon_campaign_progress.level

      [some_unit | units_to_unselect] = user.units

      # Unselect all units because first level of dungeon has max_units = 1
      Enum.each(units_to_unselect, fn unit_to_unselect ->
        {:ok, unit} = GameBackend.Units.unselect_unit(user.id, unit_to_unselect.id)
        assert unit.selected == false
      end)

      # Check that user has initial BaseSetting debuff after register

      assert Enum.any?(user.unlocks, &(&1.upgrade.name == "Dungeon.BaseSetting"))

      # Fighting a dungeon level with this user will have its units attributes reduced due to the BaseSetting debuff

      SocketTester.fight_level(socket_tester, user.id, dungeon_level.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{response_type: {:battle_result, %{initial_state: initial_state}}}
      unit_initial_state_with_debuff = Enum.find(initial_state.units, &(&1.id == some_unit.id))
      assert unit_initial_state_with_debuff.health < Units.get_health(some_unit)

      # TODO: [#CHOM-471] Check that upgrade 2 cannot be purchased before upgrade 1

      # Purchase upgrade 1 fails if the user does not have enough Pearls

      SocketTester.purchase_dungeon_upgrade(socket_tester, user.id, hp_upgrade_1.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{response_type: {:error, %Error{reason: "cant_afford"}}}

      # Add necessary currency to User
      {:ok, _} =
        Currencies.add_currency_by_name_and_game!(user.id, "Pearls", Utils.get_game_id(:champions_of_mirra), 999)

      initial_currencies = %{
        "Pearls" => Currencies.get_amount_of_currency_by_name(user.id, "Pearls")
      }

      # PurchaseDungeonUpgrade with enough currency should return an updated user.
      SocketTester.purchase_dungeon_upgrade(socket_tester, user.id, hp_upgrade_1.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{response_type: {:user, %User{} = user_with_upgrade}}

      # User should have the Unlock
      hp_upgrade_1_unlock = Enum.find(user_with_upgrade.unlocks, &(&1.upgrade.name == hp_upgrade_1.name))
      assert not is_nil(hp_upgrade_1_unlock)
      assert hp_upgrade_1_unlock.name == hp_upgrade_1.name

      # Currency should be deducted
      Enum.each(hp_upgrade_1.cost, fn currency_cost ->
        assert Currencies.get_amount_of_currency_by_name(user_with_upgrade.id, currency_cost.currency.name) ==
                 (Map.get(initial_currencies, currency_cost.currency.name) - currency_cost.amount) |> max(0)
      end)

      # Check that if we fight another level, the same unit will have a bit more health than before
      {:ok, dungeon_campaign_progress} =
        GameBackend.Campaigns.get_super_campaign_progress(user.id, dungeon_campaign.id)

      dungeon_level = dungeon_campaign_progress.level

      SocketTester.fight_level(socket_tester, user.id, dungeon_level.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{response_type: {:battle_result, %{initial_state: initial_state}}}
      unit_initial_state_with_upgrade = Enum.find(initial_state.units, &(&1.id == some_unit.id))
      assert unit_initial_state_with_upgrade.health > unit_initial_state_with_debuff.health
    end
  end

  defp fetch_last_message(socket_tester) do
    :timer.sleep(150)
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
