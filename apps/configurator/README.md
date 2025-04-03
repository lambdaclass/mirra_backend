# Configurator

This app is in charge of the configurations. Think either full game config or feature flags for A/B testing

In it you will be able to create new configurations and decide the default version to be used. Configurations are inmutable to allow rollbacks and easier A/B testing, you can always create a new one based on the default one or one in particular

To run in development you can either run it through the umbrella root or in the app repo by doing either `mix phx.server` or `iex -S mix phx.server`

## Web UI

You can visit this in [`localhost:4100`](http://localhost:4100).

In there you will be able to do the following:
- See, create, edit every game configurations, such as: characters, skills, map, etc.

## Current features

ℹ️It's highly recommended to not create duplicate configs and just edit the existing ones until we improve configurator's usability.
Otherwise game matches may break.

### Versions

Here you can add/edit config versions.
Each config currently points to a specific version, but you have to create a new specific config for each version.
E.g. if you want to edit muflus params and assign them to a different version, you have to create a new character config "Muflus" pointing to a existing version.


⚠️This needs a lot of work, so it's use is not recommended.

### Characters

Here you can add/edit character's settings.
You can:
- Change it's `active` value to enable/disable characters in game.
- Assign skills (see skills config) to each character: basic, ultimate, dash.
- Tune character params: speed, health, stamina, etc.

Its mandatory to activate a character to have a basic skin assigned, for example, if you want to add Uren you should add this this lines of code:

- Set `active` to `true` in `seeds.exs`
charactername_params = %{
  name: "valtimer",
  active: true,
  ...
  ...
}

- 4.2 Create a default skin (if needed)
charactername_basic_params = %{
  is_default: true,
  name: "Basic",
  character_id: Enum.find(characters, fn c -> c.name == "charactername" end).id
}
- Add `charactername_basic_params` to the skins list
Find the **Insert skins** section and add the new character's basic skin:

Insert skins
[
  h4ck_fenix_params,
  h4ck_basic_params,
  valtimer_frostimer_params,
  valtimer_basic_params,
  kenzu_black_lotus_params,
  kenzu_basic_params,
  otix_corrupt_underground,
  otix_basic_params
]

### Game

Here you can add/edit in-game settings.
Some of these settings are:
- Tick_rate_ms: frequency of game state updates sent to every client in-game.
- Bounty_pick_time_ms: time to pick a bounty. ⚠️ This feature is disabled, it's important to leave this as zero ⚠️
- Zone_params: ms to start the shrinking, damage, interval between zone shrink phases, etc.
- Natural_healing_interval_ms: the healing interval for every player.
- And many more...

### Map

Here you can add/edit map settings and every entity in it.
Current entities are:
- Obstacles: spikes, rocks, every colisionable entity.
- Bushes: entities where your vision is limited and you're invisible to others out of it.
- Pools: entities that put an effect to you. We currently have none but we had a slow-effect oil pool.
- Crates: entities that you can hit and destroy to get something (currently a power-up).

And the params you can tune are:
- Radius: the map radius.
- Initial_positions: the initial position for each player.
- Entities params:
  - shape: circle, polygon.
  - vertices: if it's a polygon, you must add its vertices here to draw it.
  - radius: if it's a circle, you must specify its radius.
  - type: static/dynamic. Dynamic entities can activate mechanics.
  - on_activation_mechanics: here you can tune the mechanic when the entity is activated (e.g. spikes).
  - And so on...

### Skills

Here you can add/edit skill settings and their mechanics.
Skill params:
- autoaim: boolean to toggle its autoaim behavior (on/off).
- block_movement: boolean to toggle if the character gets stuck until finishing the skill or can move while using it.
- cooldown_mechanism: time/stamina.
  - time: to use again this skill you must wait `Cooldown (ms)`.
  - stamina: you use `stamina_cost` to execute the skill. You recover 1 stamina by `Stamina Interval` in character's config.
- And more...

Mechanic params:
- Type: circle_hit, spawn_pool, leap, etc.
- Damage: damage done by the mechanic.
- Amount: amount of projectiles if the mechanic shoots a projectile.
- On_arrival_mechanic: params triggered when player arrives after jumping (e.g. `leap` type skill).
- On_explode_mechanic: params triggered when projectile explodes (e.g. `simple_shoot` type skill).

### Consumable Items

Here you can add/edit pickable items' settings.
Params:
- radius: all items are circles, so we define its size by its radius.
- active: enable/disable this item in-game (it won't spawn).
- effect: you can choose one effect to be applied after consuming the item.

### Arena Servers

Here you can add/edit arena servers' settings.
- Name: name displayed in Unity client server list button.
- Ip: ⚠️ it does nothing at the moment.
- Url: DNS of the arena server. Do **NOT** include the protocol in it (http://)
- Gateway_url: DNS of the central server to take the config from. You can choose testing or staging.
- Status: active/inactive. If active, a button is shown in Unity to play in this arena server.
- Environment: production/development/staging. It doesn't do much right now, but if it's set to production, it will be in the list to select automatically the closest (lowest ping) arena server.

## Next steps
- Discretize configs in versions/snapshots:
  - See all configurations and which one is the default.
  - See details of a specific configuration version.
  - Create a new configuration, either based on the default one or from another.
  - Change default configuration.
