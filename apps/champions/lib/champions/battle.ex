defmodule Champions.Battle do
  @moduledoc """
  The Battle module focuses on simulating the fights between teams, whether they are PvE or PvP.
  """

  require Logger

  alias Ecto.Multi
  alias GameBackend.Users.Currencies
  alias Champions.Battle.Simulator
  alias GameBackend.Campaigns
  alias GameBackend.Campaigns.{Campaign, Level, SuperCampaign, SuperCampaignProgress}
  alias GameBackend.Repo
  alias GameBackend.Units
  alias GameBackend.Users
  alias GameBackend.Users.DungeonSettlementLevel
  alias GameBackend.Users.User

  @default_max_units 6

  @doc """
  Plays a level for a user, which means fighting its units with their selected ones.
  Returns `:win` or `:loss` accordingly, and updates the user's progress if they win..
  """
  def fight_level(user_id, level_id) do
    with start_time <- :os.system_time(:millisecond),
         {:user_exists, {:ok, user}} <- {:user_exists, Users.get_user(user_id)},
         {:level, {:ok, level}} <- {:level, Campaigns.get_level(level_id)},
         {:super_campaign_progress, {:ok, %SuperCampaignProgress{level_id: current_level_id}}} <-
           {:super_campaign_progress, Campaigns.get_super_campaign_progress(user_id, level.campaign.super_campaign_id)},
         {:level_valid, true} <- {:level_valid, level_valid?(level, current_level_id, user)},
         units <- Units.get_selected_units(user_id),
         {:max_units_met, true} <- {:max_units_met, Enum.count(units) <= (level.max_units || @default_max_units)},
         {:can_afford, true} <- {:can_afford, Currencies.can_afford(user_id, level.attempt_cost)} do
      units = apply_buffs(units, user_id, level.campaign.super_campaign.name)

      {:ok, response} =
        Multi.new()
        |> Multi.run(:substract_currencies, fn _repo, _changes ->
          Currencies.substract_currencies(user_id, level.attempt_cost)
        end)
        |> Multi.run(:run_battle, fn _repo, _changes -> run_battle(user_id, level, units) end)
        |> Repo.transaction()

      end_time = :os.system_time(:millisecond)

      Logger.info("Battle took #{end_time - start_time} miliseconds")

      {:ok, response.run_battle}
    else
      {:user_exists, _} -> {:error, :user_not_found}
      {:level, {:error, :not_found}} -> {:error, :level_not_found}
      {:super_campaign_progress, {:error, :not_found}} -> {:error, :super_campaign_progress_not_found}
      {:level_valid, false} -> {:error, :level_invalid}
      {:max_units_met, false} -> {:error, :max_units_exceeded}
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

  defp level_valid?(
         %Level{
           id: id,
           campaign: %Campaign{super_campaign: %SuperCampaign{name: "Dungeon"}},
           level_number: level_number
         },
         current_level_id,
         %User{dungeon_settlement_level: %DungeonSettlementLevel{max_dungeon: max_dungeon}}
       ) do
    id == current_level_id && level_number <= max_dungeon
  end

  defp level_valid?(%Level{id: id}, current_level_id, _) do
    id == current_level_id
  end

  defp apply_buffs(units, user_id, "Dungeon") do
    buff_modifiers =
      user_id
      |> Users.get_unlocks_with_type("Dungeon")
      |> Enum.map(fn unlock -> Enum.map(unlock.upgrade.buffs, & &1.modifiers) end)
      |> List.flatten()
      |> sum_modifiers()

    Enum.map(units, &{&1, buff_modifiers})
  end

  defp apply_buffs(units, _user_id, _super_campaign), do: units

  # This will build a map with keys composed of {attribute, operation} tuples and values as the sum of the magnitudes
  # For example: %{{"attack", "Multiply"} => 0.75, {"defense", "Add"} => -100, {"defense", "Multiply"} => 0.5}}
  defp sum_modifiers(modifiers) do
    Enum.reduce(modifiers, %{}, fn modifier, acc ->
      Map.update(acc, {modifier.attribute, modifier.operation}, modifier.magnitude, &(&1 + modifier.magnitude))
    end)
  end
end
