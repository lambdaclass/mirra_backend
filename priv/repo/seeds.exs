alias GameBackend.Campaigns.Level
alias GameBackend.Items
alias GameBackend.Repo
alias GameBackend.Units
alias GameBackend.Units.Characters
alias GameBackend.Units.Unit
alias GameBackend.Users

champions_of_mirra_id = 2
units_per_level = 5


Characters.insert_character(%{
  game_id: champions_of_mirra_id,
  active: true,
  name: "Muflus",
  faction: "Araban",
  rarity: "Epic",
})

Characters.insert_character(%{
  game_id: champions_of_mirra_id,
  active: true,
  name: "Uma",
  faction: "Kaline",
  rarity: "Epic",
})

Characters.insert_character(%{
  game_id: champions_of_mirra_id,
  active: true,
  name: "Dagna",
  faction: "Merliot",
  rarity: "Epic",
})

Characters.insert_character(%{
  game_id: champions_of_mirra_id,
  active: true,
  name: "H4ck",
  faction: "Otobi",
  rarity: "Epic",
})

Items.insert_item_template(%{game_id: champions_of_mirra_id, name: "Epic Sword of Epicness", type: "weapon"})
Items.insert_item_template(%{game_id: champions_of_mirra_id, name: "Mythical Helmet of Mythicness", type: "helmet"})
Items.insert_item_template(%{game_id: champions_of_mirra_id, name: "Legendary Chestplate of Legendaryness", type: "chest"})
Items.insert_item_template(%{game_id: champions_of_mirra_id, name: "Magical Boots of Magicness", type: "boots"})

Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Gold"})
Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Gems"})
Users.Currencies.insert_currency(%{game_id: champions_of_mirra_id, name: "Scrolls"})


######################
# Campaigns creation #
######################

# TODO: Add transaction
rules = [
  %{base_level: 5, scaler: 1.5, possible_factions: ["Araban", "Kaline"], length: 10},
  %{base_level: 50, scaler: 1.7, possible_factions: ["Merliot", "Otobi"], length: 20}
]

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

    agg_difficulty = (base_level * (level_scaler |> Math.pow(level_index))) |> round()

    units =
      Enum.map(0..4, fn _ ->
        Units.unit_params_for_level(possible_characters, div(agg_difficulty, units_per_level))
        |> Map.put(:inserted_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
        |> Map.put(:updated_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
      end)
      level_units = Enum.reduce(0..(rem(agg_difficulty, units_per_level) - 1), units, fn index, units ->
        List.update_at(units, index, fn unit -> %{unit | unit_level: unit.unit_level + 1} end)
      end)

    Enum.map(level_units, fn unit_attrs ->
      Map.put(unit_attrs, :level_id, level.id)
    end)
  end)

Repo.insert_all(Unit, units, on_conflict: :nothing)
