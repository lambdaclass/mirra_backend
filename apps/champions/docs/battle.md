Sample code to create two teams of Mufluses and make them battle. Change [1..n] to modify the amount of units in each team.

```
{:ok, user_1} = Champions.Users.register("User1")
{:ok, user_2} = Champions.Users.register("User2")
team1 = Enum.map(1..6, fn slot -> GameBackend.Units.insert_unit(%{character_id: GameBackend.Units.Characters.get_character_by_name("Muflus").id, level: 1, tier: 1, rank: 1, selected: true, user_id: user_1.id, slot: slot}) |> elem(1) |> GameBackend.Repo.preload(character: [:basic_skill, :ultimate_skill]) end)
team2 = Enum.map(1..6, fn slot -> GameBackend.Units.insert_unit(%{character_id: GameBackend.Units.Characters.get_character_by_name("Muflus").id, level: 1, tier: 1, rank: 1, selected: true, user_id: user_2.id, slot: slot}) |> elem(1) |> GameBackend.Repo.preload(character: [:basic_skill, :ultimate_skill]) end)
Champions.Battle.Simulator.run_battle team1, team2
```

1v1s like this will always result in ties since they both hit each other at the same time until death. You can force one of the Mufluses to win by hardcoding their health in Champions.Units.get_max_health():

```
def get_max_health(unit) do
    if unit.id == _YOUR_ID_,
        do: 999999,
        else: unit.character.base_health
end
```
