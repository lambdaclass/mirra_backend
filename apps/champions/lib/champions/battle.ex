defmodule Champions.Battle do
  @moduledoc """
  The Battle module focuses on simulating the fights between teams, whether they are PvE or PvP.

  Fight outcomes are decided randomly, favoring the team with the higher aggregate level.
  """

  alias GameBackend.Campaigns
  alias GameBackend.Campaigns.SuperCampaignProgress
  alias GameBackend.Units
  alias GameBackend.Users

  @doc """
  Plays a level for a user, which means fighting its units with their selected ones.
  Returns `:win` or `:loss` accordingly, and updates the user's progress if they win..
  """
  def fight_level(user_id, level_id) do
    with {:user_exists, true} <- {:user_exists, Users.exists?(user_id)},
         {:level, {:ok, level}} <- {:level, Campaigns.get_level(level_id)},
         {:super_campaign_progress, {:ok, %SuperCampaignProgress{level_id: current_level_id}}} <-
           {:super_campaign_progress, Campaigns.get_super_campaign_progress(user_id, level.campaign.super_campaign_id)},
         {:level_valid, true} <- {:level_valid, current_level_id == level_id} do
      units = Units.get_selected_units(user_id)

      if battle(units, level.units) == :team_1 do
        case Users.advance_level(user_id, level.campaign.super_campaign_id) do
          # TODO: add rewards to response [CHoM-191]
          {:ok, _changes} -> :win
          _error -> {:error, :failed_to_advance}
        end
      else
        :loss
      end
    else
      {:user_exists, false} -> {:error, :user_not_found}
      {:level, {:error, :not_found}} -> {:error, :level_not_found}
      {:super_campaign_progress, {:error, :not_found}} -> {:error, :super_campaign_progress_not_found}
      {:level_valid, false} -> {:error, :level_invalid}
    end
  end

  @doc """
  Run a battle between two teams. The outcome is decided randomly, favoring the team
  with the higher aggregate level of their selected units. Returns `:team_1` or `:team_2`.
  """
  def battle(team_1, team_2) do
    team_1_agg_level =
      Enum.reduce(team_1, 0, fn unit, acc ->
        unit.level + item_level_agg(unit.items) + acc
      end)

    team_2_agg_level =
      Enum.reduce(team_2, 0, fn unit, acc ->
        unit.level + item_level_agg(unit.items) + acc
      end)

    total_level = team_1_agg_level + team_2_agg_level

    if Enum.random(1..total_level) <= team_1_agg_level, do: :team_1, else: :team_2
  end

  defp item_level_agg(items) do
    Enum.reduce(items, 0, fn item, acc -> item.level + acc end)
  end
end
