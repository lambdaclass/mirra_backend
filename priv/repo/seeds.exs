alias GameBackend.Campaigns
alias GameBackend.Campaigns.Level
alias GameBackend.Campaigns.Campaign
alias GameBackend.Items
alias GameBackend.Repo
alias GameBackend.Units
alias GameBackend.Units.Characters
alias GameBackend.Units.Unit
alias GameBackend.Users
alias GameBackend.Campaigns.Rewards.CurrencyReward

champions_of_mirra_id = 2
units_per_level = 5

Characters.insert_character(%{
  game_id: champions_of_mirra_id,
  active: true,
  name: "Muflus",
  faction: "Araban",
  rarity: "Epic"
})

Characters.insert_character(%{
  game_id: champions_of_mirra_id,
  active: true,
  name: "Uma",
  faction: "Kaline",
  rarity: "Epic"
})

Characters.insert_character(%{
  game_id: champions_of_mirra_id,
  active: true,
  name: "Dagna",
  faction: "Merliot",
  rarity: "Epic"
})

Characters.insert_character(%{
  game_id: champions_of_mirra_id,
  active: true,
  name: "H4ck",
  faction: "Otobi",
  rarity: "Epic"
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

{:ok, gold_currency} = Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Gold"})
{:ok, gems_currency} = Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Gems"})
{:ok, scrolls_currency} = Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Scrolls"})

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

quest = %{
  game_id: champions_of_mirra_id,
  name: "Main Quest",
}

{_, quest} = Campaigns.insert_quest(quest, returning: true)

# Since insert_all doesn't accept assocs, we insert the levels first and then their units
levels =
  Enum.flat_map(Enum.with_index(rules, 1), fn {campaign_rules, campaign_index} ->
    {_, campaign} = Campaigns.insert_campaign(%{
      game_id: champions_of_mirra_id,
      quest_id: quest.id,
      campaign_number: campaign_index
    }, returning: true)

    Enum.map(1..campaign_rules.length, fn level_index ->
      %{
        game_id: champions_of_mirra_id,
        campaign_id: campaign.id,
        level_number: level_index,
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
      Enum.map(0..4, fn slot ->
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
            List.update_at(units, index, fn unit -> %{unit | unit_level: unit.unit_level + 1} end)
          end)
      end

    Enum.map(level_units, fn unit_attrs ->
      Map.put(unit_attrs, :level_id, level.id)
    end)
  end)

Repo.insert_all(Unit, units, on_conflict: :nothing)

currency_rewards =
  Enum.flat_map(Enum.with_index(levels_without_units, 0), fn {level, level_index} ->
    IO.inspect("Iterating")
    currency_reward =
      %CurrencyReward{
        amount: 10 * level_index,
        currency_id: gold_currency.id,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }

    %{level_id: level.id, currency_reward: currency_reward}
  end)

IO.inspect(currency_rewards, label: "currency_rewards")
# levels_with_currency_rewards =
#   currency_rewards
#   |> Enum.map(fn {level, currency_reward} ->
#     level
#     |> Level.changeset(%{currency_rewards: [currency_reward]})
#     |> Repo.update()
#   end)

# Add the currency rewards to the levels
currency_rewards
|> Enum.map(fn {level_id, currency_reward} ->
  IO.inspect(level_id, label: "level_id")
  IO.inspect(currency_reward, label: "currency_reward")
  Repo.get!(Level, level_id)
  |> Level.changeset(%{currency_rewards: [currency_reward]})
  |> Repo.update()
end)
