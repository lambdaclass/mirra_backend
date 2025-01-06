defmodule Champions.TestUtils do
  @moduledoc """
  Utility functions for tests.
  """

  @doc """
  Generate a version.
  """
  def version_fixture(attrs \\ %{}) do
    {:ok, version} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> GameBackend.Configuration.create_version()

    version
  end

  def build_character(params \\ %{}) do
    version = version_fixture()

    Map.merge(
      %{
        game_id: 2,
        name: "Default Character Name",
        active: true,
        faction: "Kaline",
        class: "Assassin",
        base_attack: 100,
        base_health: 100,
        base_defense: 0,
        basic_skill: build_skill(%{name: "Default Basic Skill"}),
        ultimate_skill: build_skill(%{name: "Default Ultimate Skill"}),
        version_id: version.id
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
    version = version_fixture()
    game_id = GameBackend.Utils.get_game_id(:champions_of_mirra)

    Map.merge(
      %{
        name: "Default Name",
        version_id: version.id,
        game_id: game_id,
        energy_regen: 0,
        animation_duration: 0,
        mechanics: [
          %{
            trigger_delay: 0,
            apply_effects_to: build_apply_effects_to_mechanic()
          }
        ],
        cooldown: 9999
      },
      params
    )
  end

  def build_apply_effects_to_mechanic(params \\ %{}) do
    Map.merge(
      %{
        effects: [],
        targeting_strategy: %{count: 1, type: "random", target_allies: false}
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
        executions_over_time: []
      },
      params
    )
  end
end
