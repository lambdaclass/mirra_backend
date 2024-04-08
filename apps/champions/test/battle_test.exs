defmodule Champions.Test.BattleTest do
  @moduledoc """
  Test for Champions of Mirra battles.

  Since we don't have the ability to observe the state of a battle in the middle of it, we're going to work around this
  by setting our battles up in a way that we know how fights should end. So for example, if we want to check that an
  attack hits after its cooldown is over, we give its target 1 health point, and we make the maximum steps of the
  battle that said cooldown plus one. That way, we know that if the battle result is `:team_1` the skill hit, and if
  it's `:timeout`instead then it did not.
  """

  use ExUnit.Case

  alias GameBackend.Units.Characters
  alias GameBackend.Units
  alias Champions.TestUtils

  setup_all do
    target_dummy = TestUtils.create_target_dummy()
    {:ok, %{target_dummy: target_dummy}}
  end

  describe "Battle" do
    test "Execution-DealDamage with delays", %{target_dummy: target_dummy} do
      {:ok, user} = GameBackend.Users.register_user(%{username: "Execution-DealDamage User", game_id: 2})

      maximum_steps = 5
      required_steps_to_win = maximum_steps + 1
      too_long_cooldown = maximum_steps

      # Create a character with a basic skill that has a cooldown too long to execute
      # If it hit, it would deal 10 damage, which would be enough to kill the target dummy and end the battle
      basic_skill_params = TestUtils.basic_skill_params_with_cooldown(too_long_cooldown)

      character =
        TestUtils.create_character(
          "Execution-DealDamage Character",
          basic_skill_params,
          TestUtils.dummy_ultimate_skill_params()
        )

      unit = TestUtils.create_unit(character.id, user.id)

      # Check that the battle ends in timeout when the steps are not enough
      assert :timeout == Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps)

      # Decrease the cooldown and check that the battle ends in victory when the steps are enough
      {:ok, character} =
        Characters.update_character(character, %{basic_skill: Map.put(basic_skill_params, :cooldown, maximum_steps - 1)})

      {:ok, unit} = Units.get_unit(unit.id)

      assert :team_1 == Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps)

      # Add animation duration delay and check that when the execution is delayed, the battle ends in timeout when the steps are not enough
      {:ok, character} =
        Characters.update_character(character, %{
          basic_skill: Map.put(basic_skill_params, :cooldown, maximum_steps) |> Map.put(:animation_duration, 2)
        })

      {:ok, unit} = Units.get_unit(unit.id)

      assert :timeout == Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps)

      assert :team_1 ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: required_steps_to_win)

      # Add animation trigger delay and check that when the execution is delayed, the battle ends in timeout when the steps are not enough
      {:ok, character} =
        Characters.update_character(character, %{
          basic_skill: Map.put(basic_skill_params, :animation_duration, 2) |> Map.put(:animation_trigger, 2)
        })

      {:ok, unit} = Units.get_unit(unit.id)

      required_steps_to_win_with_trigger_delay = required_steps_to_win + 2

      assert :timeout ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps)

      assert :team_1 ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy],
                 maximum_steps: required_steps_to_win_with_trigger_delay
               )

      # Add initial delay and check that when the execution is delayed, the battle ends in timeout when the steps are not enough
      {:ok, _character} =
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
                    type: "DealDamage",
                    attack_ratio: 0.5,
                    energy_recharge: 50,
                    delay: 0
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

      assert :timeout == Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps)

      required_steps_to_win_with_initial_delay = required_steps_to_win + 1

      assert :team_1 ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy],
                 maximum_steps: required_steps_to_win_with_initial_delay
               )
    end

    test "Execution-DealDamage with ChanceToApply Component", %{target_dummy: target_dummy} do
      {:ok, user} = GameBackend.Users.register_user(%{username: "ComponentsUser", game_id: 2})
      cooldown = 1

      # Configure a basic skill with a ChanceToApply component of 0
      basic_skill_params =
        TestUtils.basic_skill_params_with_cooldown(cooldown)
        |> Map.put(:effects, [
          %{
            type: "instant",
            initial_delay: 0,
            components: [
              %{
                type: "ChanceToApply",
                chance: 0
              }
            ],
            modifier: [],
            executions: [
              %{
                type: "DealDamage",
                attack_ratio: 0.5,
                energy_recharge: 50,
                delay: 0
              }
            ],
            target_strategy: "random",
            target_count: 1,
            target_allies: false,
            target_attribute: "Health"
          }
        ])

      character =
        TestUtils.create_character("ComponentsCharacter", basic_skill_params, TestUtils.dummy_ultimate_skill_params())

      unit = TestUtils.create_unit(character.id, user.id)

      # Check that the battle ends in timeout even though the maximum steps is a big number
      assert :timeout == Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: 1000)

      # Change the component to have 100% chance to be applied
      {:ok, _character} =
        Characters.update_character(character, %{
          basic_skill:
            Map.put(basic_skill_params, :effects, [
              %{
                type: "instant",
                initial_delay: 0,
                components: [
                  %{
                    type: "ChanceToApply",
                    chance: 1
                  }
                ],
                modifier: [],
                executions: [
                  %{
                    type: "DealDamage",
                    attack_ratio: 0.5,
                    energy_recharge: 50,
                    delay: 0
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

      # Check that the battle ends in a victory for the team_1 right after the cooldown has elapsed
      assert :team_1 == Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: cooldown + 1)
    end

    test "Execution-DealDamage with modifiers, using the ultimate skill", %{target_dummy: target_dummy} do
      # In this test, the basic skill has a modifier that multiplies the attack by 0.1, an energy regen of 500 and a cooldown of 1.
      # The ultimate skill has an attack ratio of 0.5, so it will deal 1 point of damage (base attack * 0.1 * 0.5) every 2 steps to the target dummy, which has 10 health points.
      # This way, the battle should end in a victory for the team_1 after 21 steps.

      {:ok, user} = GameBackend.Users.register_user(%{username: "ModifiersUser", game_id: 2})
      cooldown = 1

      # Configure a basic skill with a modifier that increases the attack ratio
      basic_skill_params =
        TestUtils.basic_skill_params_with_cooldown(cooldown)
        |> Map.put(:effects, [
          %{
            type: %{"duration" => 1, "period" => 0},
            initial_delay: 0,
            components: [],
            modifiers: [
              %{
                attribute: "attack",
                modifier_operation: "Multiply",
                magnitude_calc_type: "Float",
                float_magnitude: 0.1
              }
            ],
            executions: [],
            target_strategy: "random",
            target_count: 1,
            target_allies: true,
            target_attribute: "Health"
          }
        ])

      ultimate_skill_params = TestUtils.ultimate_skill_params()

      character = TestUtils.create_character("ModifiersCharacter", basic_skill_params, ultimate_skill_params)
      unit = TestUtils.create_unit(character.id, user.id)

      assert :timeout == Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: cooldown + 1)
      assert :team_1 == Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: 21)
    end
  end
end
