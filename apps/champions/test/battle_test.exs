defmodule Champions.Test.Battle do
  @moduledoc """
  Test for Champions of Mirra messages.
  """
  use ExUnit.Case

  alias GameBackend.Repo
  alias Champions.Users
  alias GameBackend.Units.Characters
  alias GameBackend.Units

  setup do
    {:ok, target_dummy_user} = Users.register("User2")

    {:ok, target_dummy_char} =
      Characters.insert_character(%{
        game_id: 2,
        name: "Target Dummy",
        active: true,
        faction: "Kaline",
        class: "Warrior",
        base_health: 10,
        base_attack: 0,
        base_defense: 0,
        basic_skill: %{
          effects: [],
          cooldown: 9999
        },
        ultimate_skill: %{
          effects: [],
          cooldown: 9999
        }
      })

    {:ok, target_dummy} =
      Units.insert_unit(%{
        user_id: target_dummy_user.id,
        character_id: target_dummy_char.id,
        selected: true,
        level: 1,
        tier: 1
      })

    target_dummy = Repo.preload(target_dummy, character: [:basic_skill, :ultimate_skill])

    {:ok, %{target_dummy: target_dummy}}
  end

  describe "Battle" do
    test "Execution-DealDamage with delays", %{target_dummy: target_dummy} do
      {:ok, user} = GameBackend.Users.register_user(%{username: "Execution-DealDamage User", game_id: 2})

      maximum_steps = 5
      required_steps_to_win = maximum_steps + 1
      too_long_cooldown = maximum_steps

      basic_skill_params = %{
        name: "Basic",
        energy_regen: 0,
        animation_duration: 0,
        animation_trigger: 0,
        effects: [
          %{
            type: "instant",
            initial_delay: 0,
            components: [],
            modifier: [],
            executions: [
              %{
                "type" => "DealDamage",
                "attack_ratio" => 0.5,
                "energy_recharge" => 50,
                "delay" => 0
              }
            ],
            target_strategy: "random",
            target_count: 1,
            target_allies: false,
            target_attribute: "Health"
          }
        ],
        cooldown: too_long_cooldown
      }

      {:ok, character} =
        GameBackend.Units.Characters.insert_character(%{
          game_id: 2,
          name: "Execution-DealDamage Character",
          active: true,
          faction: "Kaline",
          class: "Assassin",
          base_attack: 20,
          base_health: 100,
          base_defense: 100,
          basic_skill: basic_skill_params,
          ultimate_skill: %{
            name: "None",
            energy_regen: 0,
            animation_duration: 0,
            animation_trigger: 0,
            effects: [],
            cooldown: 9999
          }
        })

      {:ok, unit} =
        Units.insert_unit(%{
          character_id: character.id,
          level: 1,
          tier: 1,
          rank: 1,
          selected: true,
          user_id: user.id,
          slot: 1
        })

      unit = Repo.preload(unit, character: [:basic_skill, :ultimate_skill])

      # Check that the battle ends in timeout when the steps are not enough
      assert :timeout == Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps)

      # Decrease the cooldown and check that the battle ends in victory when the steps are enough
      {:ok, character} =
        Characters.update_character(character, %{basic_skill: Map.put(basic_skill_params, :cooldown, maximum_steps - 1)})

      {:ok, unit} = Units.get_unit(unit.id)
      unit = Repo.preload(unit, character: [:basic_skill, :ultimate_skill])

      assert :team_1 == Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps)

      # Add animation duration delay and check that when the execution is delayed, the battle ends in timeout when the steps are not enough
      {:ok, character} =
        Characters.update_character(character, %{
          basic_skill: Map.put(basic_skill_params, :cooldown, maximum_steps) |> Map.put(:animation_duration, 2)
        })

      {:ok, unit} = Units.get_unit(unit.id)
      unit = Repo.preload(unit, character: [:basic_skill, :ultimate_skill])

      assert :timeout == Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps)

      assert :team_1 ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: required_steps_to_win)

      # Add animation trigger delay and check that when the execution is delayed, the battle ends in timeout when the steps are not enough
      {:ok, character} =
        Characters.update_character(character, %{
          basic_skill: Map.put(basic_skill_params, :animation_duration, 0) |> Map.put(:animation_trigger, 2)
        })

      {:ok, unit} = Units.get_unit(unit.id)
      unit = Repo.preload(unit, character: [:basic_skill, :ultimate_skill])

      assert :timeout == Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps)

      # assert :team_1 == Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps + 4)

      # Add initial delay and check that when the execution is delayed, the battle ends in timeout when the steps are not enough
      {:ok, character} =
        Characters.update_character(character, %{
          basic_skill:
            Map.put(basic_skill_params, :animation_trigger, 0)
            |> Map.put(:effects, [
              %{
                type: "instant",
                initial_delay: 1,
                components: [],
                modifier: [],
                executions: [
                  %{
                    "type" => "DealDamage",
                    "attack_ratio" => 0.5,
                    "energy_recharge" => 50,
                    "delay" => 0
                  }
                ],
                target_strategy: "random",
                target_count: 1,
                target_allies: false,
                target_attribute: "Health"
              }
            ])
        })

      {:ok, unit} = Units.get_unit(unit.id)
      unit = Repo.preload(unit, character: [:basic_skill, :ultimate_skill])

      assert :timeout == Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps)

      required_steps_to_win_with_initial_delay = required_steps_to_win + 1

      assert :team_1 ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy],
                 maximum_steps: required_steps_to_win_with_initial_delay
               )
    end
  end
end
