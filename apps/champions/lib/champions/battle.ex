defmodule Champions.Battle do
  @moduledoc """
  The Battle module focuses on simulating the fights between teams, whether they are PvE or PvP.

  Fight outcomes are decided randomly, favoring the team with the higher aggregate level.
  """

  alias GameBackend.Campaigns
  alias GameBackend.Users

  # @doc """
  # Run an automatic battle between two users. Only validation done is for empty teams.

  # Returns the id of the winner.
  # """
  # def pvp_battle(user_1, user_2) do
  #   user_1_units = Units.get_selected_units(user_1)
  #   user_2_units = Units.get_selected_units(user_2)

  #   cond do
  #     user_1_units == [] ->
  #       {:error, {:user_1, :no_selected_units}}

  #     user_2_units == [] ->
  #       {:error, {:user_2, :no_selected_units}}

  #     true ->
  #       case battle(user_1_units, user_2_units) do
  #         :team_1 -> user_1
  #         :team_2 -> user_2
  #       end
  #   end
  # end

  @doc """
  Plays a level for a user, which means fighting its units with their selected ones.
  Returns :win or :loss accordingly, and updates the user's progress if they win.
  """
  def fight_level(user_id, campaign_id, level_id) do
    user = Users.get_user(user_id)
    level = Campaigns.get_level(level_id)
    campaign_progression = Campaigns.get_campaign_progression(user_id, campaign_id)

    cond do
      is_nil(user) ->
        {:error, :user_not_found}

      is_nil(level) ->
        {:error, :level_not_found}

      is_nil(campaign_progression) ->
        {:error, :campaign_progression_not_found}

      true ->
        if battle(user.units, level.units) == :team_1 do
          Users.advance_level(user_id, campaign_id)
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
