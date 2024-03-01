alias GameBackend.Campaigns.Level
alias GameBackend.Units.Characters
alias GameBackend.Gacha
alias GameBackend.Items
alias GameBackend.Repo
alias GameBackend.Units
alias GameBackend.Units.Unit
alias GameBackend.Users

champions_of_mirra_id = 2
units_per_level = 5

Champions.Config.import_character_config()

muflus = Characters.get_character_by_name("Muflus")

{:ok, _muflus} = Characters.update_character(muflus, %{
  basic_skill: %{
    effects: [%{
      type: "instant",
      stat_affected: "health",
      amount: -80,
      stat_based_on: "attack",
      amount_format: "additive",
      targeting_strategy: "random", # TODO: Change back to nearest
      amount_of_targets: 2,
      targets_allies: false
    }],
    cooldown: 5
  },
  ultimate_skill: %{
    effects: [
      %{
        type: "instant",
        stat_affected: "health",
        amount: -205,
        stat_based_on: "attack",
        amount_format: "additive",
        targeting_strategy: "random", # TODO: Change back to nearest
        amount_of_targets: 2,
        targets_allies: false
      }
      # TODO: Add stun effect
      ],
  }
})

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

{:ok, _gold} = Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Gold"})
{:ok, _gems} = Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Gems"})
{:ok, scrolls} = Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Scrolls"})


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
    cost: [%{currency_id: scrolls.id, amount: 1}]
  })

{:ok, _} =
  GameBackend.Gacha.insert_box(%{
    name: "Mystic Summon",
    rank_weights: [
      %{rank: Champions.Units.get_rank(:star3), weight: 75},
      %{rank: Champions.Units.get_rank(:star4), weight: 20},
      %{rank: Champions.Units.get_rank(:star5), weight: 5}
    ],
    cost: [%{currency_id: scrolls.id, amount: 10}]
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

# Since insert_all doesn't accept assocs, we insert the levels first and then their units
levels =
  Enum.flat_map(Enum.with_index(rules, 1), fn {campaign_rules, campaign_index} ->
    Enum.map(1..campaign_rules.length, fn level_index ->
      %{
        game_id: champions_of_mirra_id,
        campaign: campaign_index,
        level_number: level_index,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }
    end)
  end)

{_, levels_without_units} =
  Repo.insert_all(Level, levels, returning: [:id, :level_number, :campaign])

units =
  Enum.flat_map(Enum.with_index(levels_without_units, 0), fn {level, level_index} ->
    campaign_rules = Enum.at(rules, level.campaign - 1)

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
