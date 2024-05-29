defmodule Champions.Config do
  @moduledoc """
  Configuration utilities.
  """

  alias GameBackend.Campaigns
  alias Champions.Units
  alias GameBackend.Items
  alias GameBackend.Units.Characters
  alias GameBackend.Units.Skills
  alias GameBackend.Users
  alias GameBackend.Users.Currencies
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
      Map.put(item_template, :game_id, GameBackend.Utils.get_game_id(:champions_of_mirra))
      |> update_in([:upgrade_costs], fn upgrade_costs ->
        Enum.map(
          upgrade_costs,
          &%{
            currency_id:
              Users.Currencies.get_currency_by_name_and_game!(&1.currency, Utils.get_game_id(:champions_of_mirra)).id,
            amount: &1.amount
          }
        )
      end)
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

  def import_dungeon_campaign_levels() do
    game_id = Utils.get_game_id(:champions_of_mirra)

    {:ok, dungeon_campaign_json} =
      Application.app_dir(:champions, "priv/dungeon_campaign.json")
      |> File.read()

    dungeon_super_campaign =
      Campaigns.get_super_campaign_by_name_and_game("Dungeon", game_id)

    [dungeon_campaign] = dungeon_super_campaign.campaigns

    supplies = Users.Currencies.get_currency_by_name_and_game("Supplies", game_id)

    Jason.decode!(dungeon_campaign_json, [{:keys, :atoms}])
    |> Enum.map(fn campaign ->
      campaign
      |> Map.put(
        :units,
        campaign.characters
        |> Enum.with_index()
        |> Enum.map(fn {character, index} ->
          %{
            level: campaign.lineup_level + Enum.random(-campaign.lineup_level_variance..campaign.lineup_level_variance),
            tier: 1,
            rank: 1,
            selected: true,
            slot: index,
            character_id:
              Characters.get_character_id_by_name_and_game_id(character, Utils.get_game_id(:champions_of_mirra))
          }
        end)
      )
      |> Map.put(:game_id, game_id)
      |> Map.put(:campaign_id, dungeon_campaign.id)
      |> Map.put(:attempt_cost, [%{currency_id: supplies.id, amount: 1}])
      |> Map.put(
        :currency_rewards,
        Enum.map(campaign.currency_rewards, fn {currency, amount} ->
          %{
            currency_id:
              currency
              |> Atom.to_string()
              |> Currencies.get_currency_by_name_and_game!(game_id)
              |> Map.get(:id),
            amount: amount
          }
        end)
      )
    end)
    |> Campaigns.upsert_levels()
  end
end
