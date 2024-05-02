defmodule Champions.Test.Units do
  @moduledoc """
  Tests for Champions of Mirra units.
  """
  alias GameBackend.Repo
  alias Champions.Utils
  alias Champions.Units
  alias Champions.Users

  use ExUnit.Case

  setup do
    {:ok, user} = Users.register("test_user")

    {:ok, character} =
      GameBackend.Units.Characters.insert_character(%{
        game_id: Utils.game_id(),
        name: "Test character",
        base_health: 100,
        faction: "Kaline"
      })

    %{user: user, character: character}
  end

  describe "units" do
    test "scaling", %{user: user, character: character} do
      {:ok, unit} =
        GameBackend.Units.insert_unit(%{
          user_id: user.id,
          character_id: character.id,
          selected: false,
          level: 1,
          tier: 1,
          rank: 1
        })

      unit = Repo.preload(unit, [:character, items: :template])

      # 100 * (((1-1)^2)/3000 + (1-1)/30 + 1) * (1.05)^(1-1) * (1.1)^(1-1)
      # 100 * (1) * (1) * (1)
      # 100
      assert Units.get_health(unit) == 100

      # Check again with more level

      {:ok, unit} = GameBackend.Units.update_unit(unit, %{level: 5})
      unit = Repo.preload(unit, [:character])

      # 100 * (((5-1)^2)/3000 + (5-1)/30 + 1) * (1.05)^(1-1) * (1.1)^(1-1)
      # 100 * (1.13866667) * (1) * (1)
      # 113.866667
      assert Units.get_health(unit) == 113

      # Check again with more level and tier

      {:ok, unit} = GameBackend.Units.update_unit(unit, %{level: 10, tier: 2})
      unit = Repo.preload(unit, [:character])

      # 100 * (((10-1)^2)/3000 + (10-1)/30 + 1) * (1.05)^(2-1) * (1.1)^(1-1)
      # 100 * (1.327) * (1.05) * (1)
      # 139.335
      assert Units.get_health(unit) == 139

      # Check again with more level, tier and rank
      {:ok, unit} = GameBackend.Units.update_unit(unit, %{level: 120, tier: 7, rank: 6})
      unit = Repo.preload(unit, [:character])

      # 100 * (((120-1)^2)/3000 + (120-1)/30 + 1) * (1.05)^(7-1) * (1.1)^(6-1)
      # 100 * (9.687) * (1.3401) * (1.61051)
      # 2090.69139968
      assert Units.get_health(unit) == 2090
    end
  end
end
