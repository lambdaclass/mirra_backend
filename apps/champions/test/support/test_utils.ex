defmodule Champions.TestUtils do
  @moduledoc """
  Utility functions for tests.
  """

  def build_character(params \\ %{}) do
    Map.merge(
      %{
        game_id: 2,
        name: "Default Character Name",
        active: true,
        faction: "Kaline",
        class: "Assassin",
        base_attack: 100,
        base_health: 100,
        base_defense: 100,
        basic_skill: build_skill(%{name: "Default Basic Skill"}),
        ultimate_skill: build_skill(%{name: "Default Ultimate Skill"})
      },
      params
    )
  end

  def build_unit(%{character_id: _character_id} = params) do
    Map.merge(
      %{
        level: 1,
        tier: 1,
        rank: 1,
        selected: true,
        slot: 1
      },
      params
    )
  end

  def build_skill(params \\ %{}) do
    Map.merge(
      %{
        name: "Default Name",
        energy_regen: 0,
        animation_duration: 0,
        animation_trigger: 0,
        effects: [],
        cooldown: 9999
      },
      params
    )
  end

  def build_effect(params \\ %{}) do
    Map.merge(
      %{
        type: %{"type" => "instant"},
        initial_delay: 0,
        components: [],
        modifiers: [],
        executions: [],
        target_strategy: "random",
        target_count: 1,
        target_allies: false,
        target_attribute: "Health"
      },
      params
    )
  end
end
