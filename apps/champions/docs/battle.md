Sample code to create two teams of Mufluses and make them battle. Change [1..n] to modify the amount of units in each team.

```
{:ok, user_1} = Champions.Users.register("User1")
{:ok, user_2} = Champions.Users.register("User2")
team1 = Enum.map(1..6, fn slot -> GameBackend.Units.insert_unit(%{character_id: GameBackend.Units.Characters.get_character_by_name("Muflus").id, level: 1, tier: 1, rank: 1, selected: true, user_id: user_1.id, slot: slot}) |> elem(1) |> GameBackend.Repo.preload([:items, character: [:basic_skill, :ultimate_skill]]) end)
team2 = Enum.map(1..6, fn slot -> GameBackend.Units.insert_unit(%{character_id: GameBackend.Units.Characters.get_character_by_name("Muflus").id, level: 1, tier: 1, rank: 1, selected: true, user_id: user_2.id, slot: slot}) |> elem(1) |> GameBackend.Repo.preload([:items, character: [:basic_skill, :ultimate_skill]]) end)
Champions.Battle.Simulator.run_battle team1, team2
```

If you play 1v1s between two same-level Mufluses, they will always result in ties since they both hit each other at the same time until death. You can force one of the Mufluses to win by increasing their level with Champions.Units.level_up(user_id, unit_id).
