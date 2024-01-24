defmodule Campaigns do
  @moduledoc """
  Documentation for `Campaigns`.
  """
  import Ecto.Query

  alias Units.Characters.Character
  alias Units.Unit

  def create_campaigns(max_level_size, rules) do
    Enum.with_index(rules)
    |> Enum.reduce(Matrix.new(Enum.count(rules), max_level_size), fn {campaign_rules,
                                                                      campaign_index},
                                                                     campaigns_matrix ->
      base_level = campaign_rules.base_level
      level_scaler = campaign_rules.scaler
      # This should be a Units.all_characters_from_factions() call
      possible_characters = Units.all_characters_from_factions(campaign_rules.possible_factions)

      Enum.reduce(0..(campaign_rules.length - 1), campaigns_matrix, fn level_index,
                                                                       matrix_accum ->
        Matrix.set(
          matrix_accum,
          campaign_index,
          level_index,
          {(base_level * (level_scaler |> Math.pow(level_index))) |> round, possible_characters}
        )
      end)
    end)
    |> remove_empty_levels()
    |> fill_difficulty_matrix_with_units()
  end

  defp fill_difficulty_matrix_with_units(campaigns) do
    Enum.map(campaigns, fn campaign ->
      Enum.map(campaign, fn {level_aggregate_unit_levels, possible_characters} ->
        create_units(
          possible_characters,
          div(level_aggregate_unit_levels, 5)
        )
        |> add_remainder_unit_levels(rem(level_aggregate_unit_levels, 5))
      end)
    end)
  end

  defp create_units(possible_characters, level) do
    Enum.map(0..4, fn _ ->
      Units.create_unit_for_level(possible_characters, level)
    end)
  end

  defp add_remainder_unit_levels(units, amount_to_add) do
    Enum.reduce(0..(amount_to_add - 1), units, fn index, units ->
      List.update_at(units, index, fn unit -> %{unit | level: unit.level + 1} end)
    end)
  end

  defp remove_empty_levels(campaigns) do
    Enum.map(campaigns, &Enum.filter(&1, fn level -> level != 0 end))
  end
end
