defmodule ChampionsOfMirra.Campaigns do
  @moduledoc """
  Documentation for `ChampionsOfMirra.Campaigns`.
  """
  @units_per_level 5

  import Ecto.Query
  alias ChampionsOfMirra.Repo
  alias ChampionsOfMirra.Campaigns.Level
  alias ChampionsOfMirra.Battle
  alias Users.User

  def get_campaigns() do
    Repo.all(from(l in Level))
    |> Repo.preload(:units)
    |> Enum.sort(fn l1, l2 -> l1.level_number < l2.level_number end)
    |> Enum.group_by(fn l -> l.campaign end)
  end

  def get_campaign(campaign_number) do
    Repo.all(from(l in Level, where: l.campaign == ^campaign_number))
    |> Repo.preload(:units)
  end

  def insert_level(attrs) do
    %Level{}
    |> Level.changeset(attrs)
    |> Repo.insert()
  end

  def get_level(level_id) do
    Repo.get(Level, level_id) |> Repo.preload(:units)
  end

  def fight_level(user_id, level_id) do
    user = Repo.get(User, user_id) |> Repo.preload(:units)
    level = Repo.get(Level, level_id) |> Repo.preload(:units)

    if Battle.battle(user.units, level.units) == :team_1 do
      :win
    else
      :loss
    end
  end

  def create_campaigns() do
    create_campaigns([
      %{base_level: 5, scaler: 1.5, possible_factions: ["Araban", "Kaline"], length: 10},
      %{base_level: 50, scaler: 1.7, possible_factions: ["Merliot", "Otobi"], length: 20}
    ])
  end

  defp create_campaigns(rules) do
    Enum.each(Enum.with_index(rules, 1), fn {campaign_rules, campaign_index} ->
      base_level = campaign_rules.base_level
      level_scaler = campaign_rules.scaler

      possible_characters = Units.all_characters_from_factions(campaign_rules.possible_factions)

      Enum.map(1..campaign_rules.length, fn level_index ->
        agg_difficulty = (base_level * (level_scaler |> Math.pow(level_index))) |> round()

        level_units =
          create_unit_params(possible_characters, div(agg_difficulty, @units_per_level))
          |> add_remainder_unit_levels(rem(agg_difficulty, @units_per_level))

        insert_level(%{units: level_units, campaign: campaign_index, level_number: level_index})
      end)
    end)
  end

  defp create_unit_params(possible_characters, level) do
    Enum.map(0..4, fn _ ->
      Units.unit_params_for_level(possible_characters, level)
    end)
  end

  defp add_remainder_unit_levels(units, amount_to_add) do
    Enum.reduce(0..(amount_to_add - 1), units, fn index, units ->
      List.update_at(units, index, fn unit -> %{unit | unit_level: unit.unit_level + 1} end)
    end)
  end
end
