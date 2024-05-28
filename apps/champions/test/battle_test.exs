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

  alias Champions.Users
  alias GameBackend.Items
  alias GameBackend.Units
  alias GameBackend.Units.Characters
  alias Champions.TestUtils

  @miliseconds_per_step 50

  setup_all do
    {:ok, target_dummy_character} =
      TestUtils.build_character(%{base_health: 10, base_attack: 0, base_defense: 0, name: "Target Dummy"})
      |> Characters.insert_character()

    {:ok, target_dummy} = %{character_id: target_dummy_character.id} |> TestUtils.build_unit() |> Units.insert_unit()
    {:ok, target_dummy} = Units.get_unit(target_dummy.id)
    {:ok, %{target_dummy: target_dummy, target_dummy_character: target_dummy_character}}
  end

  describe "Executions" do
    test "DealDamage with delays", %{target_dummy: target_dummy} do
      maximum_steps = 5
      required_steps_to_win = maximum_steps + 1
      too_long_cooldown = maximum_steps

      # Create a character with a basic skill that has a cooldown too long to execute
      # If it hit, it would deal 10 damage, which would be enough to kill the target dummy and end the battle
      basic_skill_params =
        TestUtils.build_skill(%{
          name: "DealDamage Delay",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "DealDamage",
                          attack_ratio: 0.5,
                          energy_recharge: 50
                        }
                      ]
                    })
                  ]
                })
            }
          ],
          cooldown: too_long_cooldown * @miliseconds_per_step
        })

      {:ok, character} =
        TestUtils.build_character(%{
          name: "Execution-DealDamage Character",
          basic_skill: basic_skill_params,
          ultimate_skill: TestUtils.build_skill(%{name: "DealDamage Empty Skill"}),
          # Multiplied by the attack ratio of the basic skill, we get 10
          base_attack: 20
        })
        |> Characters.insert_character()

      {:ok, unit} = TestUtils.build_unit(%{character_id: character.id}) |> Units.insert_unit()
      {:ok, unit} = Units.get_unit(unit.id)

      # Check that the battle ends in timeout when the steps are not enough
      assert "timeout" ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps).result

      # Decrease the cooldown and check that the battle ends in victory when the steps are enough
      {:ok, character} =
        Characters.update_character(character, %{
          basic_skill: Map.put(basic_skill_params, :cooldown, (maximum_steps - 2) * @miliseconds_per_step)
        })

      {:ok, unit} = Units.get_unit(unit.id)

      assert "team_1" ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps).result

      trigger_delay_steps = 2
      required_steps_to_win_with_trigger_delay_steps = required_steps_to_win + trigger_delay_steps

      # Add animation trigger delay and check that when the execution is delayed, the battle ends in timeout when the steps are not enough
      {:ok, character} =
        Characters.update_character(character, %{
          basic_skill:
            Map.put(basic_skill_params, :animation_duration, trigger_delay_steps * @miliseconds_per_step)
            |> update_in([:mechanics], fn [mechanic] ->
              [Map.put(mechanic, :trigger_delay, trigger_delay_steps * @miliseconds_per_step)]
            end)
        })

      {:ok, unit} = Units.get_unit(unit.id)

      assert "timeout" ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps).result

      assert "team_1" ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy],
                 maximum_steps: required_steps_to_win_with_trigger_delay_steps
               ).result

      # Add initial delay and check that when the execution is delayed, the battle ends in timeout when the steps are not enough
      initial_delay_steps = 1

      {:ok, _character} =
        Characters.update_character(character, %{
          basic_skill:
            basic_skill_params
            |> Map.put(:animation_trigger, 0)
            |> Map.put(:effects, [
              TestUtils.build_effect(%{
                initial_delay: initial_delay_steps * @miliseconds_per_step,
                executions: [
                  %{
                    type: "DealDamage",
                    attack_ratio: 0.5,
                    energy_recharge: 50
                  }
                ]
              })
            ])
        })

      {:ok, unit} = Units.get_unit(unit.id)

      assert "timeout" ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps).result

      required_steps_to_win_with_initial_delay = required_steps_to_win + initial_delay_steps

      assert "team_1" ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy],
                 maximum_steps: required_steps_to_win_with_initial_delay
               ).result
    end

    test "DealDamage with ChanceToApply Component", %{target_dummy: target_dummy} do
      cooldown_steps = 1

      # Configure a basic skill with a ChanceToApply component of 0
      basic_skill_params =
        TestUtils.build_skill(%{
          name: "DealDamage ChanceToApply",
          cooldown: cooldown_steps * @miliseconds_per_step,
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      components: [
                        %{
                          type: "ChanceToApply",
                          chance: 0
                        }
                      ],
                      executions: [
                        %{
                          type: "DealDamage",
                          attack_ratio: 0.5,
                          energy_recharge: 50,
                          delay: 0
                        }
                      ]
                    })
                  ]
                })
            }
          ]
        })

      {:ok, character} =
        TestUtils.build_character(%{
          name: "ComponentsCharacter",
          basic_skill: basic_skill_params,
          ultimate_skill: TestUtils.build_skill(),
          # Multiplied by the attack ratio of the basic skill, we get 10
          base_attack: 20
        })
        |> Characters.insert_character()

      {:ok, unit} =
        TestUtils.build_unit(%{character_id: character.id}) |> Units.insert_unit()

      {:ok, unit} = Units.get_unit(unit.id)

      # Check that the battle ends in timeout even though the maximum steps is a big number
      assert "timeout" == Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: 1000).result

      # Change the component to have 100% chance to be applied
      {:ok, _character} =
        Characters.update_character(character, %{
          basic_skill:
            Map.put(basic_skill_params, :mechanics, [
              %{
                trigger_delay: 0,
                apply_effects_to:
                  TestUtils.build_apply_effects_to_mechanic(%{
                    effects: [
                      TestUtils.build_effect(%{
                        components: [
                          %{
                            type: "ChanceToApply",
                            chance: 1
                          }
                        ],
                        executions: [
                          %{
                            type: "DealDamage",
                            attack_ratio: 0.5,
                            energy_recharge: 50
                          }
                        ]
                      })
                    ]
                  })
              }
            ])
        })

      {:ok, unit} = Units.get_unit(unit.id)

      # Check that the battle ends in a victory for the team_1 right after the cooldown has elapsed
      assert "team_1" ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: cooldown_steps + 1).result
    end

    test "DealDamage with modifiers, using the ultimate skill", %{target_dummy: target_dummy} do
      # In this test, the basic skill has a modifier that multiplies the attack by 0.1, an energy regen of 500 and a cooldown of 1.
      # The ultimate skill has an attack ratio of 0.5, so it will deal 1 point of damage (base attack * 0.1 * 0.5) every 2 steps to the target dummy, which has 10 health points.
      # This way, the battle should end in a victory for the team_1 after 21 steps.

      # Configure a basic skill with a modifier that increases the attack ratio
      basic_skill_params =
        TestUtils.build_skill(%{
          name: "BasicSkill3",
          cooldown: 1 * @miliseconds_per_step,
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      type: %{"type" => "duration", "duration" => 1, "period" => 0},
                      modifiers: [
                        %{
                          attribute: "attack",
                          operation: "Multiply",
                          magnitude: 0.1
                        }
                      ],
                      target_allies: true
                    })
                  ]
                })
            }
          ],
          energy_regen: 500
        })

      ultimate_skill_params =
        TestUtils.build_skill(%{
          name: "Modifiers Ultimate",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "DealDamage",
                          attack_ratio: 0.5,
                          energy_recharge: 50
                        }
                      ]
                    })
                  ]
                })
            }
          ]
        })

      {:ok, character} =
        TestUtils.build_character(%{
          name: "ModifiersCharacter",
          basic_skill: basic_skill_params,
          ultimate_skill: ultimate_skill_params,
          # Multiplied by the attack ratio of the basic skill, we get 10
          base_attack: 20
        })
        |> Characters.insert_character()

      {:ok, unit} = TestUtils.build_unit(%{character_id: character.id}) |> Units.insert_unit()
      {:ok, unit} = Units.get_unit(unit.id)

      assert "team_1" == Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: 21).result
    end

    test "DealDamage with defense" do
      maximum_steps = 5

      {:ok, target_dummy_character} =
        TestUtils.build_character(%{
          base_health: 10,
          base_attack: 0,
          base_defense: 0,
          name: "Defense Target Dummy",
          basic_skill: TestUtils.build_skill(%{name: "Defense Target Dummy Basic"}),
          ultimate_skill: TestUtils.build_skill(%{name: "Defense Target Dummy Ultimate"})
        })
        |> Characters.insert_character()

      {:ok, target_dummy} = %{character_id: target_dummy_character.id} |> TestUtils.build_unit() |> Units.insert_unit()
      {:ok, target_dummy} = Units.get_unit(target_dummy.id)

      # Create a character with a basic skill that would deal 10 damage against no armor
      basic_skill_params =
        TestUtils.build_skill(%{
          name: "DealDamage Defense",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "DealDamage",
                          attack_ratio: 1,
                          energy_recharge: 0
                        }
                      ]
                    })
                  ]
                })
            }
          ],
          cooldown: maximum_steps * @miliseconds_per_step - 1
        })

      {:ok, character} =
        TestUtils.build_character(%{
          name: "Execution-DealDamage Defense Character",
          basic_skill: basic_skill_params,
          ultimate_skill: TestUtils.build_skill(%{name: "DealDamage Defense Empty Skill"}),
          base_attack: 10
        })
        |> Characters.insert_character()

      {:ok, unit} = TestUtils.build_unit(%{character_id: character.id}) |> Units.insert_unit()
      {:ok, unit} = Units.get_unit(unit.id)

      # Battle is won if target_dummy has no defense
      assert "team_1" ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps).result

      # Give target_dummy some defense
      {:ok, target_dummy_character} = Characters.update_character(target_dummy_character, %{base_defense: 50})
      {:ok, target_dummy} = Units.get_unit(target_dummy.id)

      # Now we don't win, as we don't deal enough damage
      assert "timeout" ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps).result

      # Use the defense formula to find the amount of damage we're actually doing
      new_target_dummy_health =
        Decimal.mult(character.base_attack, Decimal.div(100, 100 + target_dummy_character.base_defense))
        |> Decimal.round()
        |> Decimal.to_integer()

      {:ok, _target_dummy_character} =
        Characters.update_character(target_dummy_character, %{base_health: new_target_dummy_health})

      {:ok, target_dummy} = Units.get_unit(target_dummy.id)

      # After reducing target_dummy health, we win again
      assert "team_1" ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps).result
    end

    test "Execution-Heal", %{target_dummy: target_dummy} do
      # We will create a battle between a team made of a healer and a target dummy, and another one with a
      # DealDamage unit. The unit will get to hit the target dummy thrice for a total of 15 damage (lethal).
      # Inbetween the attacks, the healer will heal the target dummy for 5 health points, saving them from death until the third hit.
      # Because we're healing the target dummy, the DealDamage unit doesn't get to kill the healer in time, resulting in a timeout.

      # Cooldowns will be 2 for the damage and 5 for the heal, so steps will look like this:
      # _ _ D _ _ HD _ _ D
      maximum_steps = 9
      backline_slot = 6
      heal_cooldown = 5
      damage_cooldown = 2

      heal_params =
        TestUtils.build_skill(%{
          name: "Heal",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "Heal",
                          attack_ratio: 1
                        }
                      ]
                    })
                  ],
                  targeting_strategy: %{
                    count: 1,
                    # Nearest so that the healer doesn't target himself
                    type: "nearest",
                    target_allies: true
                  }
                })
            }
          ],
          cooldown: heal_cooldown * @miliseconds_per_step
        })

      {:ok, healer_character} =
        TestUtils.build_character(%{
          name: "Heal Character",
          basic_skill: heal_params,
          ultimate_skill: TestUtils.build_skill(%{name: "Heal Empty Skill"}),
          base_attack: 5,
          # Will die if he gets hit once
          base_health: 5
        })
        |> Characters.insert_character()

      {:ok, healer} =
        TestUtils.build_unit(%{character_id: healer_character.id, slot: backline_slot}) |> Units.insert_unit()

      {:ok, healer} = Units.get_unit(healer.id)

      damage_params =
        TestUtils.build_skill(%{
          name: "Heal Test - Damage",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "DealDamage",
                          attack_ratio: 1,
                          energy_recharge: 0
                        }
                      ]
                    })
                  ],
                  targeting_strategy: %{
                    count: 1,
                    # Nearest so that he hits the target dummy
                    type: "nearest",
                    target_allies: false
                  }
                })
            }
          ],
          cooldown: damage_cooldown * @miliseconds_per_step
        })

      {:ok, damage_character} =
        TestUtils.build_character(%{
          name: "Heal Test - Damage Character",
          basic_skill: damage_params,
          ultimate_skill: TestUtils.build_skill(%{name: "Heal-Damage Empty Skill"}),
          base_attack: 5
        })
        |> Characters.insert_character()

      {:ok, damager} =
        TestUtils.build_unit(%{character_id: damage_character.id}) |> Units.insert_unit()

      {:ok, damager} = Units.get_unit(damager.id)

      # Check that the battle ends in timeout when healer heals the target dummy in time
      assert "timeout" ==
               Champions.Battle.Simulator.run_battle([healer, target_dummy], [damager], maximum_steps: maximum_steps).result

      # If healer doesn't get to heal, we lose!
      {:ok, _} =
        Characters.update_character(healer_character, %{
          basic_skill: Map.put(heal_params, :cooldown, maximum_steps * @miliseconds_per_step)
        })

      {:ok, healer} = Units.get_unit(healer.id)

      assert "team_2" ==
               Champions.Battle.Simulator.run_battle([healer, target_dummy], [damager], maximum_steps: maximum_steps).result
    end

    test "Execution-AddEnergy", %{target_dummy: target_dummy} do
      # We will create a battle between a damaging unit and a target dummy.
      # The unit's basic skill will give itself 500 energy. The ultimate will deal 10 damage to the target dummy, killing it.

      maximum_steps = 3

      add_energy_params =
        TestUtils.build_skill(%{
          name: "AddEnergy",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "AddEnergy",
                          amount: 500
                        }
                      ]
                    })
                  ],
                  targeting_strategy: %{
                    count: 1,
                    type: "random",
                    target_allies: true
                  }
                })
            }
          ],
          # -2 so that it will give time for the ultimate to be cast
          cooldown: (maximum_steps - 2) * @miliseconds_per_step
        })

      deal_damage_params =
        TestUtils.build_skill(%{
          name: "DealDamage",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "DealDamage",
                          attack_ratio: 1,
                          energy_recharge: 0
                        }
                      ]
                    })
                  ],
                  targeting_strategy: %{
                    count: 1,
                    type: "random",
                    target_allies: false
                  }
                })
            }
          ]
        })

      {:ok, character} =
        TestUtils.build_character(%{
          name: "AddEnergy Character",
          basic_skill: add_energy_params,
          ultimate_skill: deal_damage_params,
          base_attack: 10
        })
        |> Characters.insert_character()

      {:ok, unit} = TestUtils.build_unit(%{character_id: character.id}) |> Units.insert_unit()

      {:ok, unit} = Units.get_unit(unit.id)

      assert "team_1" ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps).result
    end
  end

  describe "Components" do
    test "Untargetable tag is applied" do
      # We will set up a battle between a unit with an untargetable skill and a unit that targets the nearest enemy, performing a DealDamage execution.
      # The first unit will attack and tag the second unit as untargeteable each time it hits, so the second unit will only be hit once.
      # The second unit is very weak, but the first unit will never be able to hit it, so the battle will end in a victory for the second unit.

      skill_cooldown = 5

      untargetable_params =
        TestUtils.build_skill(%{
          name: "Untargetable",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      type: %{"type" => "duration", "duration" => 5000},
                      components: [
                        %{
                          type: "ApplyTags",
                          tags: [
                            "Untargetable"
                          ]
                        }
                      ],
                      executions: [
                        %{
                          type: "DealDamage",
                          attack_ratio: 1,
                          energy_recharge: 0
                        }
                      ]
                    })
                  ],
                  targeting_strategy: %{
                    count: 1,
                    type: "nearest",
                    target_allies: false
                  }
                })
            }
          ],
          cooldown: skill_cooldown * @miliseconds_per_step
        })

      {:ok, loser_character} =
        TestUtils.build_character(%{
          name: "Loser Character",
          basic_skill: untargetable_params,
          ultimate_skill: TestUtils.build_skill(%{name: "Untargetable Empty Skill"}),
          base_attack: 5,
          base_health: 5
        })
        |> Characters.insert_character()

      {:ok, loser_unit} = TestUtils.build_unit(%{character_id: loser_character.id}) |> Units.insert_unit()

      {:ok, loser_unit} = Units.get_unit(loser_unit.id)

      damage_params =
        TestUtils.build_skill(%{
          name: "Untargetable Test - Damage",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "DealDamage",
                          attack_ratio: 1,
                          energy_recharge: 0
                        }
                      ]
                    })
                  ],
                  targeting_strategy: %{
                    count: 1,
                    # Nearest so that he hits the target dummy
                    type: "nearest",
                    target_allies: false
                  }
                })
            }
          ],
          cooldown: skill_cooldown * @miliseconds_per_step
        })

      {:ok, winner_character} =
        TestUtils.build_character(%{
          name: "Winner Character",
          basic_skill: damage_params,
          ultimate_skill: TestUtils.build_skill(%{name: "Test-Untargetable Empty Skill"}),
          base_attack: 1
        })
        |> Characters.insert_character()

      {:ok, winner_unit} =
        TestUtils.build_unit(%{character_id: winner_character.id}) |> Units.insert_unit()

      {:ok, winner_unit} = Units.get_unit(winner_unit.id)

      needed_steps = skill_cooldown * (1 + div(loser_character.base_health, winner_character.base_attack))

      assert "team_2" ==
               Champions.Battle.Simulator.run_battle([loser_unit], [winner_unit], maximum_steps: needed_steps).result
    end

    test "Nearest target is untargetable, so unit picks another target" do
      # We will set up a battle between a two units team vs a one unit team.
      # Team 1 will have a unit that tags theirself as untargetable, and another unit that can kill their target in one hit.
      # Team 2 will have a unit that can kill their nearest target in one hit. Team 1 untargetable unit will be the nearest target, so that we can test that the untargetable tag works.
      # The cooldowns are set up so that the untargetable tag is applied before the Team 2 attack is executed, and the other Team 1 unit has a longer cooldown than the Team 2 unit.
      # The battle should end in a victory in timeout, as the Team 1 targetable unit will be killed before it is able to perform an attack, and the untargetable unit will never be attacked.
      # If the untargetable tag wouldn't work, it would be a victory for Team 2.

      skill_cooldown = 5

      untargetable_params =
        TestUtils.build_skill(%{
          name: "Untargetable Skill",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      type: %{"type" => "duration", "duration" => 5000},
                      components: [
                        %{
                          type: "ApplyTags",
                          tags: [
                            "Untargetable"
                          ]
                        }
                      ],
                      executions: []
                    })
                  ],
                  targeting_strategy: %{
                    type: "self"
                  }
                })
            }
          ],
          cooldown: skill_cooldown * @miliseconds_per_step
        })

      {:ok, team_1_untargetable} =
        TestUtils.build_character(%{
          name: "Team 1 untargetable Character",
          basic_skill: untargetable_params,
          ultimate_skill: TestUtils.build_skill(%{name: "Untargetable Empty"})
        })
        |> Characters.insert_character()

      {:ok, team_1_untargetable_unit} =
        TestUtils.build_unit(%{character_id: team_1_untargetable.id, slot: 1}) |> Units.insert_unit()

      {:ok, team_1_untargetable_unit} = Units.get_unit(team_1_untargetable_unit.id)

      team_1_furthest_params =
        TestUtils.build_skill(%{
          name: "Team 1 furthest",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "DealDamage",
                          attack_ratio: 1,
                          energy_recharge: 0
                        }
                      ]
                    })
                  ],
                  targeting_strategy: %{
                    count: 1,
                    type: "random",
                    target_allies: false
                  }
                })
            }
          ],
          cooldown: (skill_cooldown + 2) * @miliseconds_per_step
        })

      {:ok, team_1_furthest} =
        TestUtils.build_character(%{
          name: "Team 1 furthest Character",
          basic_skill: team_1_furthest_params,
          ultimate_skill: TestUtils.build_skill(%{name: "Test-Untargetable Empty"}),
          base_attack: 100
        })
        |> Characters.insert_character()

      {:ok, team_1_furthest_unit} =
        TestUtils.build_unit(%{character_id: team_1_furthest.id, slot: 6}) |> Units.insert_unit()

      {:ok, team_1_furthest_unit} = Units.get_unit(team_1_furthest_unit.id)

      team_2_params =
        TestUtils.build_skill(%{
          name: "Team 2 skill",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "DealDamage",
                          attack_ratio: 1,
                          energy_recharge: 0
                        }
                      ]
                    })
                  ],
                  targeting_strategy: %{
                    count: 1,
                    type: "nearest",
                    target_allies: false
                  }
                })
            }
          ],
          cooldown: (skill_cooldown + 1) * @miliseconds_per_step
        })

      {:ok, team_2} =
        TestUtils.build_character(%{
          name: "Team 2 Character",
          basic_skill: team_2_params,
          ultimate_skill: TestUtils.build_skill(%{name: "Team 2 Empty Skill"}),
          base_attack: 100
        })
        |> Characters.insert_character()

      {:ok, team_2_unit} =
        TestUtils.build_unit(%{character_id: team_2.id, slot: 1}) |> Units.insert_unit()

      {:ok, team_2_unit} = Units.get_unit(team_2_unit.id)

      # Battle result is timeout if team_1_furthest doesn't get to attack.
      # This means that team_1_untargetable applied the untargetable tag in time and team_2_unit attacked team_1_furthest.
      # We set an exaggerated amount of steps to make sure that the battle ends in timeout.
      assert "timeout" ==
               Champions.Battle.Simulator.run_battle([team_1_untargetable_unit, team_1_furthest_unit], [team_2_unit],
                 maximum_steps: skill_cooldown + 1000
               ).result
    end
  end

  describe "Targeting Strategies" do
    test "Frontline", %{target_dummy_character: target_dummy_character} do
      maximum_steps = 5

      # Create a character with a basic skill that will deal 10 damage to the frontline
      basic_skill_params =
        TestUtils.build_skill(%{
          name: "DealDamage Frontline",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "DealDamage",
                          attack_ratio: 1,
                          energy_recharge: 0
                        }
                      ]
                    })
                  ],
                  targeting_strategy: %{
                    type: "frontline",
                    target_allies: false
                  }
                })
            }
          ],
          cooldown: maximum_steps * @miliseconds_per_step - 1
        })

      {:ok, character} =
        TestUtils.build_character(%{
          name: "Nearest Character",
          basic_skill: basic_skill_params,
          ultimate_skill: TestUtils.build_skill(%{name: "Nearest Empty Skill"}),
          base_attack: 10,
          base_health: 10
        })
        |> Characters.insert_character()

      {:ok, unit} = TestUtils.build_unit(%{character_id: character.id}) |> Units.insert_unit()
      {:ok, unit} = Units.get_unit(unit.id)

      # Create 2 target dummies in frontline slots
      [target_dummy_1, target_dummy_2] =
        Enum.map(1..2, fn slot ->
          {:ok, target_dummy} =
            %{character_id: target_dummy_character.id, slot: slot} |> TestUtils.build_unit() |> Units.insert_unit()

          {:ok, target_dummy} = Units.get_unit(target_dummy.id)
          target_dummy
        end)

      # Battle is won after only 1 skill execution
      assert "team_1" ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy_1, target_dummy_2],
                 maximum_steps: maximum_steps
               ).result

      # If we add a unit to the backline, we don't win anymore

      {:ok, target_dummy_3} =
        %{character_id: target_dummy_character.id, slot: 3} |> TestUtils.build_unit() |> Units.insert_unit()

      {:ok, target_dummy_3} = Units.get_unit(target_dummy_3.id)

      assert "timeout" ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy_1, target_dummy_2, target_dummy_3],
                 maximum_steps: maximum_steps
               ).result

      # However if there are none in the backline, we win again because we default to the frontline
      {:ok, target_dummy_1} = Units.update_unit(target_dummy_1, %{slot: 4})
      {:ok, target_dummy_2} = Units.update_unit(target_dummy_2, %{slot: 5})

      assert "team_1" ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy_1, target_dummy_2, target_dummy_3],
                 maximum_steps: maximum_steps
               ).result
    end

    test "Backline", %{target_dummy_character: target_dummy_character} do
      maximum_steps = 5

      # Create a character with a basic skill that will deal 10 damage to the backline
      basic_skill_params =
        TestUtils.build_skill(%{
          name: "DealDamage Backline",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "DealDamage",
                          attack_ratio: 1,
                          energy_recharge: 0
                        }
                      ]
                    })
                  ],
                  targeting_strategy: %{
                    type: "backline",
                    target_allies: false
                  }
                })
            }
          ],
          cooldown: maximum_steps * @miliseconds_per_step - 1
        })

      {:ok, character} =
        TestUtils.build_character(%{
          name: "Backline Character",
          basic_skill: basic_skill_params,
          ultimate_skill: TestUtils.build_skill(%{name: "Backline Empty Skill"}),
          base_attack: 10,
          base_health: 10
        })
        |> Characters.insert_character()

      {:ok, unit} = TestUtils.build_unit(%{character_id: character.id}) |> Units.insert_unit()
      {:ok, unit} = Units.get_unit(unit.id)

      # Create 4 target dummies in backline slots
      [target_dummy_1, target_dummy_2, target_dummy_3, target_dummy_4] =
        Enum.map(3..6, fn slot ->
          {:ok, target_dummy} =
            %{character_id: target_dummy_character.id, slot: slot} |> TestUtils.build_unit() |> Units.insert_unit()

          {:ok, target_dummy} = Units.get_unit(target_dummy.id)
          target_dummy
        end)

      # Battle is won after only 1 skill execution
      assert "team_1" ==
               Champions.Battle.Simulator.run_battle(
                 [unit],
                 [target_dummy_1, target_dummy_2, target_dummy_3, target_dummy_4],
                 maximum_steps: maximum_steps
               ).result

      # If we add a unit to the frontline, we don't win anymore
      {:ok, target_dummy_5} =
        %{character_id: target_dummy_character.id, slot: 2} |> TestUtils.build_unit() |> Units.insert_unit()

      {:ok, target_dummy_5} = Units.get_unit(target_dummy_5.id)

      assert "timeout" ==
               Champions.Battle.Simulator.run_battle(
                 [unit],
                 [target_dummy_1, target_dummy_2, target_dummy_3, target_dummy_4, target_dummy_5],
                 maximum_steps: maximum_steps
               ).result

      # However if they are none in the backline, we win again because we default to the frontline
      assert "team_1" ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy_5], maximum_steps: maximum_steps).result
    end

    test "All", %{target_dummy_character: target_dummy_character} do
      maximum_steps = 1

      # Create a character with a basic skill that will deal 10 damage to all the enemies
      basic_skill_params =
        TestUtils.build_skill(%{
          name: "DealDamage All Enemies",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "DealDamage",
                          attack_ratio: 1,
                          energy_recharge: 0
                        }
                      ]
                    })
                  ],
                  targeting_strategy: %{
                    type: "all",
                    target_allies: false
                  }
                })
            }
          ],
          cooldown: maximum_steps * @miliseconds_per_step - 1
        })

      {:ok, character} =
        TestUtils.build_character(%{
          name: "All Character",
          basic_skill: basic_skill_params,
          ultimate_skill: TestUtils.build_skill(%{name: "All Empty Skill"}),
          base_attack: 10,
          base_health: 10
        })
        |> Characters.insert_character()

      {:ok, unit} = TestUtils.build_unit(%{character_id: character.id}) |> Units.insert_unit()
      {:ok, unit} = Units.get_unit(unit.id)

      # Create 6 target dummies for enemy team
      target_dummies =
        Enum.map(1..6, fn slot ->
          {:ok, target_dummy} =
            %{character_id: target_dummy_character.id, slot: slot} |> TestUtils.build_unit() |> Units.insert_unit()

          {:ok, target_dummy} = Units.get_unit(target_dummy.id)
          target_dummy
        end)

      # Battle is won after only 1 skill execution
      assert "team_1" ==
               Champions.Battle.Simulator.run_battle(
                 [unit],
                 target_dummies,
                 maximum_steps: maximum_steps
               ).result
    end

    test "Self Heal" do
      # This test pairs a self healing unit with 10 health, against a damage dealing unit that makes 5 damage for each attack,
      # the second one attacks 3 times, but since the healer unit will heal itself for the same amount the same number of times,
      # the battle will end on a timeout.
      skills_cooldown = 5
      maximum_steps = (skills_cooldown + 1) * 3

      # Create a character with a basic skill that will heal 5 damage to itself
      heal_basic_skill_params =
        TestUtils.build_skill(%{
          name: "Heal Self skill",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "Heal",
                          attack_ratio: 1,
                          energy_recharge: 0
                        }
                      ]
                    })
                  ],
                  targeting_strategy: %{
                    type: "self"
                  }
                })
            }
          ],
          cooldown: skills_cooldown * @miliseconds_per_step
        })

      {:ok, heal_character} =
        TestUtils.build_character(%{
          name: "Self Heal Character",
          basic_skill: heal_basic_skill_params,
          ultimate_skill: TestUtils.build_skill(%{name: "Self Heal Empty Skill"}),
          base_attack: 5,
          base_health: 10
        })
        |> Characters.insert_character()

      {:ok, heal_unit} = TestUtils.build_unit(%{character_id: heal_character.id}) |> Units.insert_unit()
      {:ok, heal_unit} = Units.get_unit(heal_unit.id)

      deal_damage_basic_skill_params =
        TestUtils.build_skill(%{
          name: "DealDamage Skill for Self Test",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "DealDamage",
                          attack_ratio: 1,
                          energy_recharge: 50,
                          delay: 0
                        }
                      ]
                    })
                  ]
                })
            }
          ],
          cooldown: skills_cooldown * @miliseconds_per_step
        })

      # Create enemy unit
      {:ok, heal_damage_character} =
        TestUtils.build_character(%{
          name: "DealDamage Character for Self Test",
          basic_skill: deal_damage_basic_skill_params,
          ultimate_skill: TestUtils.build_skill(%{name: "Self Heal Empty Skill 2"}),
          base_attack: 5
        })
        |> Characters.insert_character()

      {:ok, damage_unit_for_heal} =
        TestUtils.build_unit(%{character_id: heal_damage_character.id}) |> Units.insert_unit()

      {:ok, damage_unit_for_heal} = Units.get_unit(damage_unit_for_heal.id)

      # Battle is timeout, since every time ally unit takes damage, it heals itself
      assert "timeout" ==
               Champions.Battle.Simulator.run_battle([heal_unit], [damage_unit_for_heal], maximum_steps: maximum_steps).result
    end

    test "Self Damage", %{target_dummy: target_dummy} do
      # This test pairs a self damaging unit agains a target dummy, the second team has no way of dealing damage to the first, but since the first team unit's
      # skill makes it damage itself for 5 damage, after 4 turns it will die, since it has 20 health.
      self_damage_cooldown = 2
      maximum_steps = (self_damage_cooldown + 1) * 4

      # Create a character with a basic skill that will self deal 5 damage
      self_damage_skill_params =
        TestUtils.build_skill(%{
          name: "Self Damage skill",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "DealDamage",
                          attack_ratio: 1,
                          energy_recharge: 0
                        }
                      ]
                    })
                  ],
                  targeting_strategy: %{
                    type: "self"
                  }
                })
            }
          ],
          cooldown: self_damage_cooldown * @miliseconds_per_step
        })

      {:ok, self_damage_character} =
        TestUtils.build_character(%{
          name: "Self Damage Character",
          basic_skill: self_damage_skill_params,
          ultimate_skill: TestUtils.build_skill(%{name: "Self Damage Empty Skill"}),
          base_attack: 5,
          base_health: 20
        })
        |> Characters.insert_character()

      {:ok, self_damage_unit} = TestUtils.build_unit(%{character_id: self_damage_character.id}) |> Units.insert_unit()
      {:ok, self_damage_unit} = Units.get_unit(self_damage_unit.id)

      # Battle is won by team_2, the dummy, since the team_1 unit damages itself
      assert "team_2" ==
               Champions.Battle.Simulator.run_battle([self_damage_unit], [target_dummy], maximum_steps: maximum_steps).result
    end
  end

  describe "Items" do
    test "Affects unit stats", %{target_dummy: target_dummy} do
      {:ok, user} = Users.register("Items User")

      maximum_steps = 5

      # Create a character with a basic skill that has a cooldown too long to execute
      # If it hit, it would deal 10 damage, which would be enough to kill the target dummy and end the battle
      basic_skill_params =
        TestUtils.build_skill(%{
          name: "Items Basic Skill",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "DealDamage",
                          attack_ratio: 1,
                          energy_recharge: 50,
                          delay: 0
                        }
                      ]
                    })
                  ]
                })
            }
          ],
          cooldown: maximum_steps - 1
        })

      {:ok, character} =
        TestUtils.build_character(%{
          name: "Items Character",
          basic_skill: basic_skill_params,
          ultimate_skill: TestUtils.build_skill(%{name: "Items Ultimate Skill"}),
          # No damage should result in timeout
          base_attack: 0
        })
        |> Characters.insert_character()

      {:ok, unit} = TestUtils.build_unit(%{character_id: character.id, user_id: user.id}) |> Units.insert_unit()
      {:ok, unit} = Units.get_unit(unit.id)

      # Check that the battle ends in timeout when the unit has no damage
      assert "timeout" ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps).result

      # Equip an item that increases the attack of the unit

      {:ok, item_template} =
        Items.insert_item_template(%{
          game_id: GameBackend.Utils.get_game_id(:champions_of_mirra),
          name: "Attack-improving weapon",
          config_id: "attack_improving_weapon",
          type: "weapon",
          rarity: 1,
          tier: 1,
          modifiers: [
            %{
              attribute: "attack",
              operation: "Add",
              value: 10
            }
          ]
        })

      {:ok, item} = Items.insert_item(%{user_id: user.id, template_id: item_template.id})

      {:ok, _} = Items.equip_item(user.id, item.id, unit.id)

      {:ok, unit} = Units.get_unit(unit.id)

      unit =
        GameBackend.Repo.preload(
          unit,
          [:user, items: :template, character: [:basic_skill, :ultimate_skill]]
        )

      assert "team_1" ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps).result
    end
  end

  describe "Speed" do
    test "Positive speed makes cooldowns shorter", %{target_dummy: target_dummy} do
      # We will create a team with two units (A speed buffing unit and a damaging unit) against a target dummy
      # Damaging unit will deal 5 damage per hit, and the target dummy has 10 health points.
      # Cooldown for the damaging unit is 4 steps, so it can hit only once in an 8 step battle.
      # Speeding unit will buff its speed up to a point where cooldowns are halved, so it gets to hit twice and team 1 wins.

      # Battle will go like this (S = speed buff, D = damage)
      # _ _ S _ D S _ D
      maximum_steps = 8
      speed_cooldown = 2
      damage_cooldown = 4

      speed_params =
        TestUtils.build_skill(%{
          name: "SpeedBuff-SpeedBuffSkill",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      type: %{
                        "type" => "permanent"
                      },
                      modifiers: [
                        %{
                          attribute: "speed",
                          operation: "Add",
                          magnitude: 100
                        }
                      ]
                    })
                  ],
                  targeting_strategy: %{
                    count: 1,
                    # Nearest so that the speeder doesn't target himself
                    type: "nearest",
                    target_allies: true
                  }
                })
            }
          ],
          cooldown: speed_cooldown * @miliseconds_per_step
        })

      {:ok, speed_character} =
        TestUtils.build_character(%{
          name: "SpeedBuff-SpeedBuffCharacter",
          basic_skill: speed_params,
          ultimate_skill: TestUtils.build_skill(%{name: "SpeedBuff-SpeedBuffEmptySkill"})
        })
        |> Characters.insert_character()

      {:ok, speeder} =
        TestUtils.build_unit(%{character_id: speed_character.id, slot: 1}) |> Units.insert_unit()

      {:ok, speeder} = Units.get_unit(speeder.id)

      damage_params =
        TestUtils.build_skill(%{
          name: "SpeedBuff-DamageSkill",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "DealDamage",
                          attack_ratio: 1,
                          energy_recharge: 0
                        }
                      ]
                    })
                  ],
                  targeting_strategy: %{
                    count: 1,
                    type: "nearest",
                    target_allies: false
                  }
                })
            }
          ],
          cooldown: damage_cooldown * @miliseconds_per_step
        })

      {:ok, damager_character} =
        TestUtils.build_character(%{
          name: "SpeedBuff-DamageCharacter",
          basic_skill: damage_params,
          ultimate_skill: TestUtils.build_skill(%{name: "SpeedBuff-DamageEmptySkill"}),
          base_attack: 5
        })
        |> Characters.insert_character()

      {:ok, damager} =
        TestUtils.build_unit(%{character_id: damager_character.id, slot: 2}) |> Units.insert_unit()

      {:ok, damager} = Units.get_unit(damager.id)

      assert "team_1" ==
               Champions.Battle.Simulator.run_battle([speeder, damager], [target_dummy], maximum_steps: maximum_steps).result
    end

    test "Negative speed makes cooldowns longer" do
      # We will create a team with a speed debuffing unit and a team with a damaging unit.
      # Damaging unit will deal 5 damage per hit, and the speed buffing unit has 10 health points.
      # Cooldown for the damaging unit is 2 steps, so it can hit twice in a 7 step battle.
      # Speeding unit will debuff the damaging unit's speed down to a point where cooldowns are doubled, so it gets to hit only once
      # so we get a timeout.

      # Battle will go like this (S = speed debuff, D = damage)
      # _ S D S _ S _
      maximum_steps = 7
      speed_cooldown = 1
      damage_cooldown = 2

      speed_params =
        TestUtils.build_skill(%{
          name: "SpeedDebuff-SpeedDebuffSkill",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      type: %{
                        "type" => "duration",
                        "duration" => -1,
                        "period" => 0
                      },
                      modifiers: [
                        %{
                          attribute: "speed",
                          operation: "Add",
                          magnitude: -50
                        }
                      ]
                    })
                  ],
                  targeting_strategy: %{
                    count: 1,
                    type: "random",
                    target_allies: false
                  }
                })
            }
          ],
          cooldown: speed_cooldown * @miliseconds_per_step
        })

      {:ok, speed_character} =
        TestUtils.build_character(%{
          name: "SpeedDebuff-SpeedDebuffCharacter",
          basic_skill: speed_params,
          ultimate_skill: TestUtils.build_skill(%{name: "SpeedDebuff-DebuffEmptySkill"}),
          base_health: 10
        })
        |> Characters.insert_character()

      {:ok, speeder} =
        TestUtils.build_unit(%{character_id: speed_character.id, slot: 1}) |> Units.insert_unit()

      {:ok, speeder} = Units.get_unit(speeder.id)

      damage_params =
        TestUtils.build_skill(%{
          name: "SpeedDebuff-DamageSkill",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions: [
                        %{
                          type: "DealDamage",
                          attack_ratio: 1,
                          energy_recharge: 0
                        }
                      ]
                    })
                  ],
                  targeting_strategy: %{
                    count: 1,
                    type: "nearest",
                    target_allies: false
                  }
                })
            }
          ],
          cooldown: damage_cooldown * @miliseconds_per_step
        })

      {:ok, damager_character} =
        TestUtils.build_character(%{
          name: "SpeedDebuff-DamageCharacter",
          basic_skill: damage_params,
          ultimate_skill: TestUtils.build_skill(%{name: "SpeedDebuff-DamageEmptySkill"}),
          base_attack: 5
        })
        |> Characters.insert_character()

      {:ok, damager} =
        TestUtils.build_unit(%{character_id: damager_character.id, slot: 2}) |> Units.insert_unit()

      {:ok, damager} = Units.get_unit(damager.id)

      assert "timeout" ==
               Champions.Battle.Simulator.run_battle([speeder], [damager], maximum_steps: maximum_steps).result

      # If battle lasted 1 step longer, speeder dies
      assert "team_2" ==
               Champions.Battle.Simulator.run_battle([speeder], [damager], maximum_steps: maximum_steps + 1).result
    end
  end

  describe "Executions over time" do
    test "DealDamage over time", %{target_dummy: target_dummy} do
      # We will create a battle between a damaging unit and a target dummy.
      # The unit's basic skill will deal 4 points of damage to the target dummy over 3 steps, killing it in the third one.
      # The battle should finish with a victory for team_1 after the third step, or in timeout if the steps are less than 3.
      maximum_steps = 3

      deal_damage_over_time_params =
        TestUtils.build_skill(%{
          name: "DealDamageOverTime",
          mechanics: [
            %{
              trigger_delay: 0,
              apply_effects_to:
                TestUtils.build_apply_effects_to_mechanic(%{
                  effects: [
                    TestUtils.build_effect(%{
                      executions_over_time: [
                        %{
                          type: "DealDamageOverTime",
                          attack_ratio: 1,
                          apply_tags: ["Burn"],
                          interval: 3 * @miliseconds_per_step
                        }
                      ]
                    })
                  ],
                  targeting_strategy: %{
                    count: 1,
                    type: "nearest",
                    target_allies: false
                  }
                })
            }
          ],
          cooldown: 0
        })

      {:ok, character} =
        TestUtils.build_character(%{
          name: "DealDamageOverTime Character",
          basic_skill: deal_damage_over_time_params,
          ultimate_skill: TestUtils.build_skill(%{name: "DealDamageOverTime Empty Skill"}),
          base_attack: 4
        })
        |> Characters.insert_character()

      {:ok, unit} = TestUtils.build_unit(%{character_id: character.id}) |> Units.insert_unit()

      {:ok, unit} = Units.get_unit(unit.id)

      assert "team_1" ==
               Champions.Battle.Simulator.run_battle([unit], [target_dummy], maximum_steps: maximum_steps).result
    end
  end
end
