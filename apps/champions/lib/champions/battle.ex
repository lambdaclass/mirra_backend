defmodule Champions.Battle do
  @moduledoc """
  The Battle module focuses on simulating the fights between teams, whether they are PvE or PvP.

  Fight outcomes are decided randomly, favoring the team with the higher aggregate level.
  """

  alias GameBackend.Campaigns
  alias GameBackend.Users

  @doc """
  Plays a level for a user, which means fighting its units with their selected ones.
  Returns :win or :loss accordingly.

  No tracking for level progress is done yet.
  """
  def fight_level(user_id, level_id) do
    user = Users.get_user(user_id)
    level = Campaigns.get_level(level_id)

    cond do
      is_nil(user) ->
        {:error, :user_not_found}

      is_nil(level) ->
        {:error, :level_not_found}

      true ->
        if battle(user.units, level.units) == :team_1 do
          :win
        else
          :loss
        end
    end
  end

  @doc """
  Run a battle between two teams. The outcome is decided randomly, favoring the team
  with the higher aggregate level of their selected units. Returns `:team_1` or `:team_2`.
  """
  def battle(team_1, team_2) do
    team_1_agg_level =
      Enum.reduce(team_1, 0, fn unit, acc ->
        unit.unit_level + item_level_agg(unit.items) + acc
      end)

    team_2_agg_level =
      Enum.reduce(team_2, 0, fn unit, acc ->
        unit.unit_level + item_level_agg(unit.items) + acc
      end)

    total_level = team_1_agg_level + team_2_agg_level

    if Enum.random(1..total_level) <= team_1_agg_level, do: :team_1, else: :team_2
  end

  defp item_level_agg(items) do
    Enum.reduce(items, 0, fn item, acc -> item.level + acc end)
  end
end
