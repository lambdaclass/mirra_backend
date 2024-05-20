defmodule Champions.Battle do
  @moduledoc """
  The Battle module focuses on simulating the fights between teams, whether they are PvE or PvP.
  """

  require Logger

  alias Ecto.Multi
  alias GameBackend.Users.Currencies
  alias Champions.Battle.Simulator
  alias GameBackend.Campaigns
  alias GameBackend.Campaigns.SuperCampaignProgress
  alias GameBackend.Repo
  alias GameBackend.Units
  alias GameBackend.Users

  @doc """
  Plays a level for a user, which means fighting its units with their selected ones.
  Returns `:win` or `:loss` accordingly, and updates the user's progress if they win..
  """
  def fight_level(user_id, level_id) do
    with start_time <- :os.system_time(:millisecond),
         {:user_exists, true} <- {:user_exists, Users.exists?(user_id)},
         {:level, {:ok, level}} <- {:level, Campaigns.get_level(level_id)},
         {:super_campaign_progress, {:ok, %SuperCampaignProgress{level_id: current_level_id}}} <-
           {:super_campaign_progress, Campaigns.get_super_campaign_progress(user_id, level.campaign.super_campaign_id)},
         {:level_valid, true} <- {:level_valid, current_level_id == level_id},
         {:can_afford, true} <- {:can_afford, Currencies.can_afford(user_id, level.attempt_costs)} do
      units = Units.get_selected_units(user_id)

      {:ok, response} =
        Multi.new()
        |> Multi.run(:substract_currencies, fn _repo, _changes ->
          Currencies.substract_currencies(user_id, level.attempt_costs)
        end)
        |> Multi.run(:run_battle, fn _repo, _changes -> run_battle(user_id, level, units) end)
        |> Repo.transaction()

      end_time = :os.system_time(:millisecond)

      Logger.info("Battle took #{end_time - start_time} miliseconds")

      {:ok, response.run_battle}
    else
      {:user_exists, false} -> {:error, :user_not_found}
      {:level, {:error, :not_found}} -> {:error, :level_not_found}
      {:super_campaign_progress, {:error, :not_found}} -> {:error, :super_campaign_progress_not_found}
      {:level_valid, false} -> {:error, :level_invalid}
      {:can_afford, false} -> {:error, :cant_afford}
    end
  end

  defp run_battle(user_id, level, units) do
    case Simulator.run_battle(units, level.units) do
      %{result: "team_1"} = result ->
        # TODO: add rewards to response [CHoM-191]
        case Champions.Campaigns.advance_level(user_id, level.campaign.super_campaign_id) do
          {:ok, _changes} -> {:ok, result}
          _error -> {:error, :failed_to_advance}
        end

      result ->
        {:ok, result}
    end
  end
end
