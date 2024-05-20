alias GameBackend.Utils
alias GameBackend.Campaigns
alias GameBackend.Campaigns.Campaign
alias GameBackend.Campaigns.Level
alias GameBackend.Campaigns.Rewards.AfkRewardRate
alias GameBackend.Campaigns.Rewards.CurrencyReward
alias GameBackend.Gacha
alias GameBackend.Repo
alias GameBackend.Units
alias GameBackend.Units.Unit
alias GameBackend.Users
alias GameBackend.Users.DungeonSettlementLevel
alias GameBackend.Users.KalineTreeLevel

curse_of_mirra_id = Utils.get_game_id(:curse_of_mirra)
champions_of_mirra_id = Utils.get_game_id(:champions_of_mirra)
units_per_level = 6

{:ok, _skills} = Champions.Config.import_skill_config()

{:ok, _characters} = Champions.Config.import_character_config()

{:ok, gold_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Gold"})

{:ok, _gems_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Gems"})

{:ok, arcane_crystals_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Arcane Crystals"})

{:ok, hero_souls_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Hero Souls"})

{:ok, summon_scrolls_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Summon Scrolls"})

{:ok, _mystic_scrolls_currency} =
  Users.Currencies.insert_currency(%{
    game_id: champions_of_mirra_id,
    name: "Mystic Summon Scrolls"
  })

{:ok, _curse_gold} =
  Users.Currencies.insert_currency(%{
    game_id: curse_of_mirra_id,
    name: "Gold"
  })

{:ok, _curse_gems} =
  Users.Currencies.insert_currency(%{
    game_id: curse_of_mirra_id,
    name: "Gems"
  })

{:ok, _curse_feature_tokens} =
  Users.Currencies.insert_currency(%{
    game_id: curse_of_mirra_id,
    name: "Feature Tokens"
  })

{:ok, _fertilizer_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Fertilizer"})

{:ok, supplies_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Supplies"})

{:ok, blueprints_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Blueprints"})

{:ok, _trophies_currency} =
  Users.Currencies.insert_currency(%{game_id: curse_of_mirra_id, name: "Trophies"})

{:ok, _items} = Champions.Config.import_item_template_config()

{:ok, _} =
  Gacha.insert_box(%{
    name: "Basic Summon",
    rank_weights: [
      %{rank: Champions.Units.get_rank(:star1), weight: 90},
      %{rank: Champions.Units.get_rank(:star2), weight: 70},
      %{rank: Champions.Units.get_rank(:star3), weight: 30},
      %{rank: Champions.Units.get_rank(:star4), weight: 7},
      %{rank: Champions.Units.get_rank(:star5), weight: 3}
    ],
    cost: [%{currency_id: summon_scrolls_currency.id, amount: 1}]
  })

{:ok, _} =
  GameBackend.Gacha.insert_box(%{
    name: "Mystic Summon",
    rank_weights: [
      %{rank: Champions.Units.get_rank(:star3), weight: 75},
      %{rank: Champions.Units.get_rank(:star4), weight: 20},
      %{rank: Champions.Units.get_rank(:star5), weight: 5}
    ],
    cost: [%{currency_id: summon_scrolls_currency.id, amount: 10}]
  })

# TODO: remove these inserts after completing CHoM-#360 (https://github.com/lambdaclass/champions_of_mirra/issues/360)
kaline_tree_levels =
  Enum.map(1..50, fn level_number ->
    %{
      level: level_number,
      fertilizer_level_up_cost: level_number * 100,
      gold_level_up_cost: level_number * 100,
      unlock_features: [],
      inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
  end)

{_, kaline_tree_levels} =
  Repo.insert_all(KalineTreeLevel, kaline_tree_levels, returning: [:id, :level])

afk_reward_rates =
  Enum.flat_map(Enum.with_index(kaline_tree_levels, 1), fn {level, level_index} ->
    [
      %{
        kaline_tree_level_id: level.id,
        rate: 10.0 * (level_index - 1),
        currency_id: gold_currency.id,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      },
      %{
        kaline_tree_level_id: level.id,
        rate: 2.0 * (level_index - 1),
        currency_id: hero_souls_currency.id,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      },
      %{
        kaline_tree_level_id: level.id,
        rate: 3.0 * (level_index - 1),
        currency_id: arcane_crystals_currency.id,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }
    ]
  end)

Repo.insert_all(AfkRewardRate, afk_reward_rates)

######################
# Campaigns creation #
######################

# Rules needed are:
#   - `base_level`: the aggregate level of all units in the first level of the campaign
#   - `scaler`: used to calculate the aggregate level of the campaign's levels, multiplying the previous level's aggregate by this value
#   - `possible_factions`: which factions the randomly generated units can belong to
#   - `length`: the length of the campaign.
# Each of the rule maps given represents a campaign, and the number of the campaign (stored in the Level)
# will be equal to the index of its rules in the list (1-based).

rules = [
  %{base_level: 5, scaler: 1.2, possible_factions: ["Araban", "Kaline"], length: 10},
  %{base_level: 50, scaler: 1.3, possible_factions: ["Merliot", "Otobi"], length: 20}
]

main_campaign = %{
  game_id: champions_of_mirra_id,
  name: "Main Campaign"
}

dungeon_super_campaign = %{
  game_id: champions_of_mirra_id,
  name: "Dungeon"
}

{_, main_campaign} = Campaigns.insert_super_campaign(main_campaign, returning: true)

{_, dungeon_super_campaign} =
  Campaigns.insert_super_campaign(dungeon_super_campaign, returning: true)

# Since insert_all doesn't accept assocs, we insert the levels first and then their units
levels =
  Enum.flat_map(Enum.with_index(rules, 1), fn {campaign_rules, campaign_index} ->
    {_, campaign} =
      Campaigns.insert_campaign(
        %{
          game_id: champions_of_mirra_id,
          super_campaign_id: main_campaign.id,
          campaign_number: campaign_index
        },
        returning: true
      )

    Enum.map(1..campaign_rules.length, fn level_index ->
      %{
        game_id: champions_of_mirra_id,
        campaign_id: campaign.id,
        level_number: level_index,
        experience_reward: 100 * level_index,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }
    end)
  end)

{_, levels_without_embeds} =
  Repo.insert_all(Level, levels, returning: [:id, :level_number, :campaign_id])

units =
  Enum.flat_map(Enum.with_index(levels_without_embeds, 0), fn {level, level_index} ->
    campaign_number = Repo.get!(Campaign, level.campaign_id).campaign_number
    campaign_rules = Enum.at(rules, campaign_number - 1)

    base_level = campaign_rules.base_level
    level_scaler = campaign_rules.scaler

    possible_characters = Units.all_characters_from_factions(campaign_rules.possible_factions)

    agg_difficulty = (base_level * Math.pow(level_scaler, level_index)) |> round()

    units =
      Enum.map(1..6, fn slot ->
        Units.unit_params_for_level(
          possible_characters,
          div(agg_difficulty, units_per_level),
          slot
        )
        |> Map.put(:inserted_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
        |> Map.put(:updated_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
      end)

    # Add the remaining unit levels to match the level difficulty
    level_units =
      case rem(agg_difficulty, units_per_level) do
        0 ->
          units

        missing_levels ->
          Enum.reduce(0..missing_levels, units, fn index, units ->
            List.update_at(units, index, fn unit -> %{unit | level: unit.level + 1} end)
          end)
      end

    Enum.map(level_units, fn unit_attrs ->
      Map.put(unit_attrs, :campaign_level_id, level.id)
    end)
  end)

Repo.insert_all(Unit, units, on_conflict: :nothing)

# Add the rewards of each level.
# The calculation of the `amount` field is done following the specification found in https://docs.google.com/spreadsheets/d/177mvJS75LecaAEpyYotQEcrmhGJWI424UnkE2JHLmyY
currency_rewards =
  Enum.map(levels_without_embeds, fn level ->
    %{
      level_id: level.id,
      amount: 10 * (20 + level.level_number),
      currency_id: gold_currency.id,
      inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
  end)

currency_rewards =
  currency_rewards ++
    Enum.map(levels_without_embeds, fn level ->
      %{
        level_id: level.id,
        amount: (10 * (15 + level.level_number - 1) * 1.025) |> round(),
        currency_id: hero_souls_currency.id,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }
    end)

Repo.insert_all(CurrencyReward, currency_rewards, on_conflict: :nothing)

_dungeon_settlement_levels =
  Enum.map(1..20, fn level_number ->
    {:ok, dungeon_settlement_level} =
      Repo.insert(
        DungeonSettlementLevel.changeset(
          %DungeonSettlementLevel{},
          %{
            level: level_number,
            max_dungeon: level_number * 10,
            max_factional: level_number * 5,
            supply_limit: level_number * 5,
            afk_reward_rates: [
              %{rate: 10.0 * (level_number - 1), currency_id: supplies_currency.id}
            ],
            level_up_costs: [
              %{currency_id: gold_currency.id, amount: level_number * 100},
              %{currency_id: blueprints_currency.id, amount: level_number * 50}
            ],
            inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
            updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
          }
        )
      )

    dungeon_settlement_level
  end)

dungeon_rules =
  %{
    base_level: 5,
    scaler: 1.05,
    possible_factions: ["Araban", "Kaline", "Merliot", "Otobi"],
    length: 200
  }

# Since insert_all doesn't accept assocs, we insert the levels first and then their units
{:ok, dungeon_campaign} =
  Campaigns.insert_campaign(
    %{
      game_id: champions_of_mirra_id,
      super_campaign_id: dungeon_super_campaign.id,
      campaign_number: 1
    },
    returning: true
  )

dungeon_levels =
  Enum.map(1..dungeon_rules.length, fn level_index ->
    %{
      game_id: champions_of_mirra_id,
      campaign_id: dungeon_campaign.id,
      level_number: level_index,
      experience_reward: 100 * level_index,
      inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
  end)

{_, levels_without_units} =
  Repo.insert_all(Level, dungeon_levels, returning: [:id, :level_number, :campaign_id])

units =
  Enum.flat_map(Enum.with_index(levels_without_units, 0), fn {level, level_index} ->
    campaign_number = Repo.get!(Campaign, level.campaign_id).campaign_number

    base_level = dungeon_rules.base_level
    level_scaler = dungeon_rules.scaler

    possible_characters = Units.all_characters_from_factions(dungeon_rules.possible_factions)

    agg_difficulty = (base_level * Math.pow(level_scaler, level_index)) |> round()

    units =
      Enum.map(1..6, fn slot ->
        Units.unit_params_for_level(
          possible_characters,
          div(agg_difficulty, units_per_level),
          slot
        )
        |> Map.put(:inserted_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
        |> Map.put(:updated_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
      end)

    # Add the remaining unit levels to match the level difficulty
    level_units =
      case rem(agg_difficulty, units_per_level) do
        0 ->
          units

        missing_levels ->
          Enum.reduce(0..missing_levels, units, fn index, units ->
            List.update_at(units, index, fn unit -> %{unit | level: unit.level + 1} end)
          end)
      end

    Enum.map(level_units, fn unit_attrs ->
      Map.put(unit_attrs, :campaign_level_id, level.id)
    end)
  end)

Repo.insert_all(Unit, units, on_conflict: :nothing)
