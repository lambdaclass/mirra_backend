# Champions Of Mirra

Application for the Champions Of Mirra game. Implements modules for:

- Battle: Simulates battles. For now, only allows fights between a user and a level from the campaign. Battle outcome is affected by the level of units and equipped items of each team.
- Campaigns: Creates a campaign with customizable difficulty, in the shape of 5 units per level.
- Items: Handles logic for Items. Items are owned by a user and can be equipped to units to enhance their level in battle. They can also be leveled up at a scaling gold price.
- Units: Handles logic for Units. Units are owned by a user and can be selected to fight in the user's lineup.
- Users: Handles logic for Users.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `curse_of_mirra` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:curse_of_mirra, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/curse_of_mirra>.

## Useful Commands

### Users

#### Create User

```
{:ok, user} = Champions.Users.register("userName")
```

#### Get User by Id

```
user = Champions.Users.get_user(user_id)
```

#### Get User by Username

```
user = Champions.Users.get_user_by_username("userName")
```

#### Add Currency to User

```
{:ok, currency} = Champions.Currencies.add_currency(user.id, Currencies.get_currency_by_name!(currency_name).id, currency_amount)
```

---

### Campaigns & Levels

#### Get Campaigns

```
campaigns = Champions.Campaigns.get_campaigns()
```

#### Get Campaign
Returns list of levels

```
campaign = Champions.Campaigns.get_campaign(campaign_number)
```

#### Get Level

```
level = Champions.Campaigns.get_level(level_id)
```

#### Fight Level

```
result = Champions.Battle.fight_level(user_id, level_id)
```

---

### Units

#### Create Character
The parameters described are the required ones, the optional ones that can also be added are: rarity, base_health, base_attack, base_armor, basic_skill_id and ultimate_skill_id
```
{:ok, character} = GameBackend.Units.Characters.insert_character(%{game_id: Champions.Utils.game_id(), active: true, name: character_name, faction: faction_name})
```

#### Create Unit

```
GameBackend.Units.insert_unit(%{character_id: character_id, user_id: user_id, level: level, tier: tier, selected: false, slot: nil})
```

#### Get Unit by Id
```
{:ok, unit} = GameBackend.Units.get_unit(unit_id)
```

#### Update Unit
The first parameter is the unit to modify, the second one is all the parameters you want to modify for that unit.

```
GameBackend.Units.update_unit(unit, %{tier: tier, selected: selected, slot: slot})
```

#### Select Unit

```
unit = Champions.Units.select_unit(user_id, unit_id, slot)
```

#### Unselect Unit

```
unit = Champions.Units.unselect_unit(user_id, unit_id)
```

#### Level Up Unit
Returns `{:error, reason}` if not successful, E.g. `{:error, :cant_afford}` if the user doesn't have enough currency to level up the unit.

```
unit = Champions.Units.level_up(user_id, unit_id)
```

---

### Items

#### Equip Item

```
item = Champions.Items.equip_item(user_id, item_id, unit_id)
```

#### Unequip Item

```
item = Champions.Items.unequip_item(user_id, item_id)
```

#### Get Item by Id

```
item = Champions.Items.get_item(item_id)
```

#### Create Item Template

```
{:ok, item_template} = GameBackend.Items.insert_item_template(%{game_id: Champions.Utils.game_id(), name: name, type: item_type})
```

#### Create Item
```
{:ok, item} = GameBackend.Items.insert_item(%{user_id: user_id, template_id: template_id, level: level})
```

#### Level Up Item
Returns `{:error, reason}` if not successful, E.g. `{:error, :cant_afford}` if the user doesn't have enough currency to level up the unit.

```
item = Champions.Items.level_up(user_id, item_id)
```

---
