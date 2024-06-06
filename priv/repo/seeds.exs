alias GameBackend.Users.Currencies.Currency
alias GameBackend.{Campaigns, Gacha, Items, Repo, Units, Users, Utils}
alias GameBackend.Campaigns.{Campaign, Level, Rewards.CurrencyReward}
alias GameBackend.Users.Upgrade
alias GameBackend.Units.{Characters, Unit}
alias GameBackend.CurseOfMirra.Config

curse_of_mirra_id = Utils.get_game_id(:curse_of_mirra)
champions_of_mirra_id = Utils.get_game_id(:champions_of_mirra)
units_per_level = 6

### Champions Currencies

{:ok, _skills} = Champions.Config.import_skill_config()

{:ok, _characters} = Champions.Config.import_character_config()

{:ok, gold_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Gold"})

{:ok, _gems_currency} =
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

{:ok, _4_star_shards_currency} =
  Users.Currencies.insert_currency(%{
    game_id: champions_of_mirra_id,
    name: "4* Shards"
  })

{:ok, _5_star_shards_currency} =
  Users.Currencies.insert_currency(%{
    game_id: champions_of_mirra_id,
    name: "5* Shards"
  })

{:ok, _fertilizer_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Fertilizer"})

{:ok, _supplies_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Supplies"})

{:ok, _blueprints_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Blueprints"})

{:ok, pearls_currency} =
  Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Pearls"})

### Curse Currencies

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
  Enum.flat_map(levels_without_embeds, fn level ->
    [
      %{
        level_id: level.id,
        amount: 10 * (20 + level.level_number),
        currency_id: gold_currency.id,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      },
      %{
        level_id: level.id,
        amount: (10 * (15 + level.level_number - 1) * 1.025) |> round(),
        currency_id: hero_souls_currency.id,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }
    ]
  end)

Repo.insert_all(CurrencyReward, currency_rewards, on_conflict: :nothing)

Champions.Config.import_dungeon_settlement_levels_config()

Champions.Config.import_kaline_tree_levels_config()

{:ok, _initial_debuff} =
  Repo.insert(
    Upgrade.changeset(%Upgrade{}, %{
      game_id: champions_of_mirra_id,
      name: "Dungeon.BaseSetting",
      description: "This upgrade sets the base settings for the dungeon.",
      group: -1,
      buffs: [
        %{
          modifiers: [
            %{attribute: "max_level", magnitude: 10, operation: "Add"},
            %{attribute: "health", magnitude: 0.1, operation: "Multiply"},
            %{attribute: "attack", magnitude: 0.1, operation: "Multiply"}
          ]
        }
      ]
    })
  )

{:ok, sample_hp_1} =
  Repo.insert(
    Upgrade.changeset(%Upgrade{}, %{
      game_id: champions_of_mirra_id,
      name: "Dungeon.HPUpgrade1",
      description: "This upgrade increases the health of all units by 5%.",
      group: 1,
      cost: [
        %{currency_id: pearls_currency.id, amount: 5}
      ],
      buffs: [
        %{
          modifiers: [
            %{attribute: "health", magnitude: 0.05, operation: "Multiply"}
          ]
        }
      ]
    })
  )

{:ok, _sample_hp_2} =
  Repo.insert(
    Upgrade.changeset(%Upgrade{}, %{
      game_id: champions_of_mirra_id,
      name: "Dungeon.HPUpgrade2",
      description: "This upgrade increases the health of all units by 10%.",
      group: 1,
      cost: [
        %{currency_id: pearls_currency.id, amount: 10}
      ],
      upgrade_dependency_depends_on: [
        %{depends_on_id: sample_hp_1.id}
      ],
      buffs: [
        %{
          modifiers: [
            %{attribute: "health", magnitude: 1.1, operation: "Multiply"}
          ]
        }
      ]
    })
  )

# Since insert_all doesn't accept assocs, we insert the levels first and then their units
{:ok, _dungeon_campaign} =
  Campaigns.insert_campaign(
    %{
      game_id: champions_of_mirra_id,
      super_campaign_id: dungeon_super_campaign.id,
      campaign_number: 1
    },
    returning: true
  )

Champions.Config.import_dungeon_levels_config()

##################### CURSE OF MIRRA #####################
# Insert characters
Config.get_characters_config()
|> Enum.each(fn char_params ->
  Map.put(char_params, :game_id, curse_of_mirra_id)
  |> Map.put(:faction, "none")
  |> Characters.insert_character()
end)

# Insert items templates
Config.get_items_templates_config()
|> Enum.each(fn item_template ->
  purchase_costs =
    Enum.map(item_template.purchase_costs, fn purchase_cost ->
      Map.put(
        purchase_cost,
        :currency_id,
        Repo.get_by!(Currency, name: purchase_cost.currency, game_id: curse_of_mirra_id)
        |> Map.get(:id)
      )
    end)

  Map.put(item_template, :game_id, curse_of_mirra_id)
  |> Map.put(:rarity, 0)
  |> Map.put(:config_id, item_template.name)
  |> Map.put(:purchase_costs, purchase_costs)
  |> Items.insert_item_template()
end)

################### END CURSE OF MIRRA ###################
