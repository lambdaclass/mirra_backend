defmodule Champions.TestUtils do
  @moduledoc """
  Utility functions for tests.
  """
  alias GameBackend.Repo
  alias Champions.Users
  alias GameBackend.Units.Characters
  alias GameBackend.Units

  def create_target_dummy() do
    {:ok, target_dummy_user} = Users.register("BattleUser")

    # Create a character that won't ever get to attack because of its long cooldown. His health will be 10.
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
          effects: []
        }
      })

    create_unit(target_dummy_char.id, target_dummy_user.id)
  end

  def create_character(name, basic_skill_params, ultimate_skill_params) do
    {:ok, character} =
      GameBackend.Units.Characters.insert_character(%{
        game_id: 2,
        name: name,
        active: true,
        faction: "Kaline",
        class: "Assassin",
        base_attack: 20,
        base_health: 100,
        base_defense: 100,
        basic_skill: basic_skill_params,
        ultimate_skill: ultimate_skill_params
      })

    character
  end

  def create_unit(character_id, user_id) do
    {:ok, unit} =
      Units.insert_unit(%{
        character_id: character_id,
        level: 1,
        tier: 1,
        rank: 1,
        selected: true,
        user_id: user_id,
        slot: 1
      })

    Repo.preload(unit, character: [:basic_skill, :ultimate_skill])
  end

  def basic_skill_params_with_cooldown(cooldown, skill_name) do
    %{
      # Add a random number to the name to avoid conflicts
      name: skill_name,
      energy_regen: 500,
      animation_duration: 0,
      animation_trigger: 0,
      effects: [
        %{
          type: %{type: "instant"},
          initial_delay: 0,
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
      ],
      cooldown: cooldown
    }
  end

  def ultimate_skill_params(skill_name) do
    %{
      # Add a random number to the name to avoid conflicts
      name: skill_name,
      energy_regen: 0,
      animation_duration: 0,
      animation_trigger: 0,
      effects: [
        %{
          type: %{type: "instant"},
          initial_delay: 0,
          components: [],
          modifiers: [],
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
      ]
    }
  end

  def dummy_ultimate_skill_params(skill_name) do
    %{
      # Add a random number to the name to avoid conflicts
      name: skill_name,
      energy_regen: 0,
      animation_duration: 0,
      animation_trigger: 0,
      effects: []
    }
  end
end
