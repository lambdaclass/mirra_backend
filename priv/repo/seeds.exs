alias GameBackend.Campaigns
alias GameBackend.Campaigns.Level
alias GameBackend.Campaigns.Campaign
alias GameBackend.Gacha
alias GameBackend.Items
alias GameBackend.Repo
alias GameBackend.Units
alias GameBackend.Units.Unit
alias GameBackend.Users
alias GameBackend.Campaigns.Rewards.CurrencyReward

champions_of_mirra_id = 2
units_per_level = 5

{:ok, _skills} = Champions.Config.import_skill_config()
Champions.Config.import_character_config()

Items.insert_item_template(%{
  game_id: champions_of_mirra_id,
  name: "Epic Sword of Epicness",
  type: "weapon"
})

Items.insert_item_template(%{
  game_id: champions_of_mirra_id,
  name: "Mythical Helmet of Mythicness",
  type: "helmet"
})

Items.insert_item_template(%{
  game_id: champions_of_mirra_id,
  name: "Legendary Chestplate of Legendaryness",
  type: "chest"
})

Items.insert_item_template(%{
  game_id: champions_of_mirra_id,
  name: "Magical Boots of Magicness",
  type: "boots"
})

{:ok, gold_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Gold"})

{:ok, gems_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Gems"})

{:ok, _arcane_crystals_currency} =
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

super_campaign = %{
  game_id: champions_of_mirra_id,
  name: "Main Campaign"
}

{_, super_campaign} = Campaigns.insert_super_campaign(super_campaign, returning: true)

# Since insert_all doesn't accept assocs, we insert the levels first and then their units
levels =
  Enum.flat_map(Enum.with_index(rules, 1), fn {campaign_rules, campaign_index} ->
    {_, campaign} =
      Campaigns.insert_campaign(
        %{
          game_id: champions_of_mirra_id,
          super_campaign_id: super_campaign.id,
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

{_, levels_without_units} =
  Repo.insert_all(Level, levels, returning: [:id, :level_number, :campaign_id])

units =
  Enum.flat_map(Enum.with_index(levels_without_units, 0), fn {level, level_index} ->
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
  Enum.map(levels_without_units, fn level ->
    %{
      level_id: level.id,
      amount: 10 * (20 + level.level_number),
      currency_id: gold_currency.id,
      afk_reward: false,
      inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
  end)

currency_rewards =
  currency_rewards ++
    Enum.map(levels_without_units, fn level ->
      %{
        level_id: level.id,
        amount: (10 * (15 + level.level_number - 1) * 1.025) |> round(),
        currency_id: hero_souls_currency.id,
        afk_reward: false,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }
    end)

Repo.insert_all(CurrencyReward, currency_rewards, on_conflict: :nothing)

afk_reward_increments =
  Enum.flat_map(Enum.with_index(levels_without_units, 1), fn {level, level_index} ->
    [
      %{
        level_id: level.id,
        amount: 10 * level_index,
        currency_id: gold_currency.id,
        afk_reward: true,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      },
      %{
        level_id: level.id,
        amount: level_index,
        currency_id: gems_currency.id,
        afk_reward: true,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }
    ]
  end)

Repo.insert_all(CurrencyReward, afk_reward_increments, on_conflict: :nothing)
