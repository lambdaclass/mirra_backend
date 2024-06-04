defmodule Champions.Config do
  @moduledoc """
  Configuration utilities.

  The functions here read configuration files from the app's priv folder and import them into the database.
  They are meant to be used during the application's initialization (in the seeds.exs file) but can also be called during runtime.
  These functions will overwrite existing data in the database when unique identifiers are repeated (like character names) through upserts.

  Take into account that these functions do not remove existing data from the database, so if you want to remove old data, you should do it manually.
  For example, if you initially defined characters A and B in your `characters.json` file, and later on kept only A and reimported the file, B would still be in the database.
  """

  alias Champions.Units
  alias GameBackend.Items
  alias GameBackend.Units.Characters
  alias GameBackend.Units.Skills
  alias GameBackend.Users
  alias GameBackend.Utils

  @doc """
  Imports the skills configuration from 'skills.json' in the app's priv folder.
  """
  def import_skill_config() do
    {:ok, skills_json} =
      Application.app_dir(:champions, "priv/skills.json")
      |> File.read()

    Jason.decode!(skills_json, [{:keys, :atoms}])
    |> Skills.upsert_skills()
  end

  @doc """
  Imports the characters configuration from 'characters.csv' in the app's priv folder.
  """
  def import_character_config() do
    [_headers | characters] =
      Application.app_dir(:champions, "priv/characters.csv")
      |> File.stream!()
      |> CSV.decode!()
      |> Enum.to_list()

    characters
    |> Enum.map(fn [
                     name,
                     quality,
                     ranks_dropped_in,
                     class,
                     faction,
                     attack,
                     health,
                     defense,
                     basic_skill,
                     ultimate_skill
                   ] ->
      %{
        name: name,
        quality: String.downcase(quality) |> String.to_atom() |> Units.get_quality(),
        ranks_dropped_in: String.split(ranks_dropped_in, "/"),
        class: class,
        faction: faction,
        base_attack: Integer.parse(attack) |> elem(0),
        base_health: Integer.parse(health) |> elem(0),
        base_defense: Integer.parse(defense) |> elem(0),
        game_id: Utils.get_game_id(:champions_of_mirra),
        basic_skill_id: get_skill_id(basic_skill),
        ultimate_skill_id: get_skill_id(ultimate_skill),
        active: true
      }
    end)
    |> Characters.upsert_characters()
  end

  defp get_skill_id(skill) do
    case Skills.get_skill_by_name(skill) do
      nil -> nil
      skill -> skill.id
    end
  end

  def import_item_template_config() do
    {:ok, item_templates_json} =
      Application.app_dir(:champions, "priv/item_templates.json")
      |> File.read()

    Jason.decode!(item_templates_json, [{:keys, :atoms}])
    |> Enum.map(fn item_template ->
      item_template
      |> Map.put(:game_id, GameBackend.Utils.get_game_id(:champions_of_mirra))
      |> update_in([:upgrade_costs], &transform_currency_costs/1)
    end)
    |> Items.upsert_item_templates()
  end

  def import_proximity_config() do
    {:ok, proximities_json} =
      Application.app_dir(:champions, "priv/proximities.json")
      |> File.read()

    proximities = Jason.decode!(proximities_json, [{:keys, :atoms}])

    Enum.each(0..5, fn index ->
      Application.put_env(
        :champions,
        :"slot_#{index + 1}_proximities",
        %{
          ally_proximities: Enum.at(proximities.ally_proximities, index),
          enemy_proximities: Enum.at(proximities.enemy_proximities, index)
        },
        persistent: true
      )
    end)
  end

  def import_fusion_config() do
    {:ok, fusion_json} =
      Application.app_dir(:champions, "priv/fusion.json")
      |> File.read()

    fusion_rules = Jason.decode!(fusion_json, [{:keys, :atoms}])

    Enum.each(fusion_rules, fn fusion_rule ->
      Application.put_env(
        :champions,
        :"rank_#{fusion_rule.rank}_fusion",
        %{
          same_character_amount: fusion_rule.same_character_amount,
          same_character_rank: fusion_rule.same_character_rank,
          same_faction_amount: fusion_rule.same_faction_amount,
          same_faction_rank: fusion_rule.same_faction_rank
        },
        persistent: true
      )
    end)
  end

  def import_dungeon_settlement_levels_config() do
    game_id = Utils.get_game_id(:champions_of_mirra)

    {:ok, dungeon_settlement_levels_json} =
      Application.app_dir(:champions, "priv/dungeon_settlement_levels.json")
      |> File.read()

    Jason.decode!(dungeon_settlement_levels_json, [{:keys, :atoms}])
    |> Enum.map(fn dungeon_settlement_level ->
      dungeon_settlement_level
      |> update_in([:level_up_costs], &transform_currency_costs/1)
      |> Map.put(
        :afk_reward_rates,
        Enum.map(
          dungeon_settlement_level.afk_reward_rates,
          fn {currency, rate} ->
            %{
              currency_id:
                currency
                |> Atom.to_string()
                |> Users.Currencies.get_currency_by_name_and_game!(game_id)
                |> Map.get(:id),
              rate: rate
            }
          end
        )
      )
    end)
    |> Users.upsert_dungeon_settlement_levels()
  end

  defp transform_currency_costs(currency_costs) do
    Enum.map(
      currency_costs,
      &%{
        currency_id:
          Users.Currencies.get_currency_by_name_and_game!(&1.currency, Utils.get_game_id(:champions_of_mirra)).id,
        amount: &1.amount
      }
    )
  end
end
