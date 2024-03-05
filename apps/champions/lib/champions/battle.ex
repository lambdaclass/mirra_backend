defmodule Champions.Battle do
  @moduledoc """
  The Battle module focuses on simulating the fights between teams, whether they are PvE or PvP.

  Fight outcomes are decided randomly, favoring the team with the higher aggregate level.
  """

  alias Champions.Battle.Simulator
  alias GameBackend.Campaigns
  alias GameBackend.Campaigns.CampaignProgress
  alias GameBackend.Units
  alias GameBackend.Users

  @doc """
  Plays a level for a user, which means fighting its units with their selected ones.
  Returns `:win` or `:loss` accordingly, and updates the user's progress if they win..
  """
  def fight_level(user_id, level_id) do
    with {:user, {:ok, _user}} <- {:user, Users.get_user(user_id)},
         {:level, {:ok, level}} <- {:level, Campaigns.get_level(level_id)},
         {:campaign_progress, {:ok, %CampaignProgress{level_id: current_level_id}}} <-
           {:campaign_progress, Campaigns.get_campaign_progress(user_id, level.campaign_id)},
         {:level_valid, true} <- {:level_valid, current_level_id == level_id} do
      units = Units.get_selected_units(user_id)

      level_units =
        level.units
        |> Enum.map(&GameBackend.Repo.preload(&1, character: [:basic_skill, :ultimate_skill]))

      seed = Enum.random(1..500)
      IO.inspect("Running battle with seed #{seed}")

      if Simulator.run_battle(units, level_units, seed) == :team_1 do
        case Users.advance_level(user_id, level.campaign_id) do
          # TODO: add rewards to response [CHoM-191]
          {:ok, _changes} -> :win
          _error -> {:error, :failed_to_advance}
        end
      else
        :loss
      end
    else
      {:user, {:error, :not_found}} -> {:error, :user_not_found}
      {:level, {:error, :not_found}} -> {:error, :level_not_found}
      {:campaign_progress, {:error, :not_found}} -> {:error, :campaign_progress_not_found}
      {:level_valid, false} -> {:error, :level_invalid}
    end
  end
end
