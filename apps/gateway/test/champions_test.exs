defmodule Gateway.Test.Champions do
  @moduledoc """
  Test for Champions of Mirra messages.
  """
  import Ecto.Query

  use ExUnit.Case

  alias Champions.{Units, Users, Utils}
  alias GameBackend.Campaigns.Rewards.CurrencyReward
  alias GameBackend.Repo
  alias GameBackend.Items
  alias GameBackend.Users.Currencies.CurrencyCost
  alias GameBackend.Users.Currencies
  alias Gateway.Serialization.AfkRewards
  alias Gateway.Serialization.SuperCampaignProgresses

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

      {:ok, previous_scrolls} = Currencies.add_currency_by_name!(user.id, "Summon Scrolls", 1)

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

      # Get user's first SuperCampaignProgress
      [super_campaign_progress | _] = user.super_campaign_progresses

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

      # Get user's first SuperCampaignProgress
      [super_campaign_progress | _] = user.super_campaign_progresses

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

      [advanced_super_campaign_progress | _] = advanced_user.super_campaign_progresses

      assert user.id == advanced_user.id
      assert advanced_super_campaign_progress.level_id != level_id
      assert advanced_super_campaign_progress.level.level_number == level_number + 1
    end

    test "can not fight a Level that is not the next one in the SuperCampaignProgress", %{
      socket_tester: socket_tester
    } do
      # Register user
      {:ok, user} = Users.register("invalid_battle_user")

      # Get user's first SuperCampaignProgress
      [super_campaign_progress | _] = user.super_campaign_progresses

      # Get the level of the SuperCampaignProgress
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

  describe "afk rewards" do
    test "winning battles increments the afk rewards", %{socket_tester: socket_tester} do
      {:ok, user} = Users.register("AfkRewardsUser")

      # Check that the initial afk reward rates are all 0
      assert Enum.all?(user.afk_reward_rates, fn rate -> rate.rate == 0 end)

      # Get initial afk rewards
      SocketTester.get_afk_rewards(socket_tester, user.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{response_type: {:afk_rewards, %AfkRewards{afk_rewards: initial_afk_rewards}}}

      # Check that the initial afk rewards are all 0
      assert Enum.all?(initial_afk_rewards, fn reward -> reward.amount == 0 end)

      # Set up a powerful team to win a level with the user. That should increment the afk rewards rates
      Enum.each(user.units, fn unit ->
        GameBackend.Units.update_unit(unit, %{level: 9999})
      end)

      [super_campaign_progress | _] = user.super_campaign_progresses
      level_id = super_campaign_progress.level_id
      SocketTester.fight_level(socket_tester, user.id, level_id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:battle_result, _ = battle_result}
      }

      assert battle_result.result == "team_1"

      # Get advanced user
      SocketTester.get_user(socket_tester, user.id)
      fetch_last_message(socket_tester)
      assert_receive %WebSocketResponse{response_type: {:user, %User{} = advanced_user}}

      # Check that the gold and gems afk rewards rates are now greater than the initial rewards, and the other rates are still 0
      rewardable_currencies_ids = ["Gold", "Gems"] |> Enum.map(&Currencies.get_currency_by_name!(&1).id)

      assert Enum.all?(advanced_user.afk_reward_rates, fn rate ->
               case rate.currency_id in rewardable_currencies_ids do
                 true ->
                   rate.rate > 0

                 false ->
                   rate.rate == 0
               end
             end)

      # Claim afk rewards
      currencies_before_claiming = advanced_user.currencies

      # Simulate waiting 2 seconds before claiming the rewards
      seconds_to_wait = 2
      {:ok, advanced_user_with_rewards} = Users.get_user(advanced_user.id)

      {:ok, _} =
        advanced_user_with_rewards
        |> GameBackend.Users.User.changeset(%{
          last_afk_reward_claim: DateTime.utc_now() |> DateTime.add(-seconds_to_wait, :second)
        })
        |> Repo.update()

      SocketTester.claim_afk_rewards(socket_tester, advanced_user.id)
      fetch_last_message(socket_tester)
      assert_receive %WebSocketResponse{response_type: {:user, %User{} = claimed_user}}

      # Check that the user has received gold and gems.
      # The amount should be greater than the initial amount and be in the range of the expected amount considering the time waited.
      # We add 10% to the time waited to account for the time it takes to process the message.
      assert Enum.all?(claimed_user.currencies, fn currency ->
               user_currency = Enum.find(claimed_user.currencies, &(&1.currency.name == currency.currency.name))

               currency_id = Currencies.get_currency_by_name!(currency.currency.name).id

               case Enum.find(claimed_user.afk_reward_rates, &(&1.currency_id == currency_id)) do
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

      # Play another level to increment the afk rewards rates again
      SocketTester.get_user_super_campaign_progresses(socket_tester, advanced_user.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:super_campaign_progresses, %SuperCampaignProgresses{} = super_campaign_progresses}
      }

      [super_campaign_progress | _] = super_campaign_progresses.super_campaign_progresses
      next_level_id = super_campaign_progress.level_id
      SocketTester.fight_level(socket_tester, advanced_user.id, next_level_id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:battle_result, _ = battle_result}
      }

      assert battle_result.result == "team_1"

      # Get new user
      SocketTester.get_user(socket_tester, user.id)
      fetch_last_message(socket_tester)
      assert_receive %WebSocketResponse{response_type: {:user, %User{} = more_advanced_user}}

      # Check that the rewardable currencies afk rewards rates are now greater than the rewards before the second battle, and the other rates are still 0
      # Get the current level number and check that the afk rewards rates have increased proportionally
      SocketTester.get_user_super_campaign_progresses(socket_tester, advanced_user.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:super_campaign_progresses, %SuperCampaignProgresses{} = super_campaign_progresses}
      }

      [super_campaign_progress | _] = super_campaign_progresses.super_campaign_progresses
      current_level_id = super_campaign_progress.level_id

      current_level_afk_rewards_increments =
        Repo.all(from(r in CurrencyReward, where: r.level_id == ^current_level_id and r.afk_reward))

      assert Enum.all?(more_advanced_user.afk_reward_rates, fn rate ->
               case rate.currency_id in rewardable_currencies_ids do
                 true ->
                   previous_rate = Enum.find(advanced_user.afk_reward_rates, &(&1.currency_id == rate.currency_id)).rate

                   afk_reward_increment =
                     Enum.find(current_level_afk_rewards_increments, &(&1.currency_id == rate.currency_id)).amount

                   new_rate = previous_rate + afk_reward_increment
                   rate.rate > previous_rate

                 false ->
                   rate.rate == 0
               end
             end)
    end
  end

  describe "items" do
    test "get item", %{socket_tester: socket_tester} do
      {:ok, user} = Users.register("GetItemUser")

      {:ok, epic_bow} =
        Items.insert_item_template(%{
          game_id: Utils.game_id(),
          name: "Epic Bow of Testness",
          type: "weapon",
          modifiers: [
            %{
              attribute: "attack",
              modifier_operation: "Multiply",
              base_value: 1.6
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
      assert fetched_item.level == 1
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
          game_id: Utils.game_id(),
          name: "Epic Upgrader of All Stats",
          type: "weapon",
          base_modifiers: [
            %{
              attribute: "attack",
              modifier_operation: "Multiply",
              base_value: attack_multiplier
            },
            %{
              attribute: "defense",
              modifier_operation: "Multiply",
              base_value: defense_multiplier
            },
            %{
              attribute: "health",
              modifier_operation: "Add",
              base_value: health_adder
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
      assert Units.get_attack(unit_with_item) in trunc(attack_multiplier * attack_before_equip)..trunc(
               attack_multiplier *
                 attack_before_equip + 1
             )

      assert Units.get_defense(unit_with_item) in trunc(defense_multiplier * defense_before_equip)..trunc(
               defense_multiplier *
                 defense_before_equip +
                 1
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

    test "level up item", %{socket_tester: socket_tester} do
      # Register user
      {:ok, user} = Users.register("LevelUpItemUser")

      {:ok, epic_axe} =
        Items.insert_item_template(%{
          game_id: Utils.game_id(),
          name: "Epic Axe of Testness",
          type: "weapon",
          modifiers: [
            %{
              attribute: "attack",
              modifier_operation: "Multiply",
              base_value: 1.6
            }
          ]
        })

      {:ok, item} = Items.insert_item(%{user_id: user.id, template_id: epic_axe.id, level: 1})

      # Set user gold to the minimum amount required to level up the item
      Currencies.add_currency(
        user.id,
        Currencies.get_currency_by_name!("Gold").id,
        1 - Currencies.get_amount_of_currency_by_name(user.id, "Gold")
      )

      gold_amount_before_level_up = Currencies.get_amount_of_currency_by_name(user.id, "Gold")

      # LevelUpItem
      :ok = SocketTester.level_up_item(socket_tester, user.id, item.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{
        response_type: {:item, %Item{} = leveled_up_item}
      }

      assert leveled_up_item.level == item.level + 1
      assert Currencies.get_amount_of_currency_by_name(user.id, "Gold") < gold_amount_before_level_up

      # LevelUpItem once again to check that we can't afford it
      :ok = SocketTester.level_up_item(socket_tester, user.id, item.id)
      fetch_last_message(socket_tester)

      assert_receive %WebSocketResponse{response_type: {:error, %Error{reason: "cant_afford"}}}
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
