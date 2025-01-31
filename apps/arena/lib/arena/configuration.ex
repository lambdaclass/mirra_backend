defmodule Arena.Configuration do
  @moduledoc """
  Module in charge of configuration related things
  """

  def get_character_config(name, config) do
    Enum.find(config.characters, fn character -> character.name == name end)
  end

  def get_game_config() do
    client_config = get_client_config()

    get_current_game_configuration()
    |> Map.put(:client_config, client_config)
  end

  def get_game_mode_configuration(name, type) do
    gateway_url = Application.get_env(:arena, :gateway_url)
    query_params = URI.encode_query(%{"name" => name, "type" => type})
    url = "#{gateway_url}/curse/configuration/game_modes?#{query_params}"

    case Finch.build(:get, url, [{"content-type", "application/json"}])
         |> Finch.request(Arena.Finch) do
      {:ok, payload} ->
        {:ok,
         Jason.decode!(payload.body, [{:keys, :atoms}])
         |> Map.update!(:map_mode_params, fn map_mode_params ->
           Enum.map(map_mode_params, fn map_mode_param -> parse_map_mode_params(map_mode_param) end)
         end)}

      {:error, _} ->
        {:error, %{}}
    end
  end

  defp parse_map_mode_params(map_mode_params) do
    %{
      map_mode_params
      | solo_initial_positions: Enum.map(map_mode_params.solo_initial_positions, &parse_position/1),
        team_initial_positions: Enum.map(map_mode_params.team_initial_positions, &parse_position/1)
    }
  end

  defp get_current_game_configuration do
    gateway_url = Application.get_env(:arena, :gateway_url)

    {:ok, payload} =
      Finch.build(:get, "#{gateway_url}/curse/configuration/current", [{"content-type", "application/json"}])
      |> Finch.request(Arena.Finch)

    Jason.decode!(payload.body, [{:keys, :atoms}])
    |> Map.update!(:map, fn maps ->
      map =
        maps
        |> Enum.filter(fn map -> map.active end)
        |> Enum.random()

      parse_map_config(map)
    end)
    |> Map.update!(:characters, fn characters ->
      parse_characters_config(characters)
    end)
    |> Map.update!(:items, fn items ->
      parse_items_config(items)
    end)
    |> Map.update!(:game, fn game ->
      parse_game_config(game)
    end)
  end

  defp get_client_config() do
    {:ok, config_json} =
      Application.app_dir(:arena, "priv/client_config.json")
      |> File.read()

    Jason.decode!(config_json, [{:keys, :atoms}])
  end

  defp parse_characters_config(characters) do
    Enum.map(characters, fn character ->
      character_skills = %{
        "1" => parse_skill_config(character.basic_skill),
        "2" => parse_skill_config(character.ultimate_skill),
        "3" => parse_skill_config(character.dash_skill)
      }

      %{character | mana_recovery_damage_multiplier: maybe_to_float(character.mana_recovery_damage_multiplier)}
      |> Map.put(:skills, character_skills)
      |> Map.drop([:basic_skill, :ultimate_skill, :dash_skill])
    end)
  end

  defp parse_items_config(items) do
    Enum.map(items, fn item ->
      %{
        item
        | effect: parse_effect(item.effect),
          radius: maybe_to_float(item.radius),
          mechanics: parse_mechanics_config(item.mechanics)
      }
    end)
  end

  defp parse_skill_config(%{cooldown_mechanism: "stamina", stamina_cost: cost} = skill_config) when cost >= 0 do
    skill_config = parse_combo_config(skill_config)
    mechanics = parse_mechanics_config(skill_config.mechanics)
    %{skill_config | mechanics: mechanics, on_owner_effect: parse_effect(skill_config.on_owner_effect)}
  end

  defp parse_skill_config(%{cooldown_mechanism: "time", cooldown_ms: cooldown} = skill_config) when cooldown >= 0 do
    skill_config = parse_combo_config(skill_config)
    mechanics = parse_mechanics_config(skill_config.mechanics)
    %{skill_config | mechanics: mechanics, on_owner_effect: parse_effect(skill_config.on_owner_effect)}
  end

  defp parse_skill_config(%{cooldown_mechanism: "mana", mana_cost: cost} = skill_config) when cost >= 0 do
    mechanics = parse_mechanics_config(skill_config.mechanics)
    %{skill_config | mechanics: mechanics, on_owner_effect: parse_effect(skill_config.on_owner_effect)}
  end

  defp parse_skill_config(skill_config) do
    case skill_config.cooldown_mechanism do
      "stamina" ->
        raise "Invalid Skill config for `#{skill_config[:name]}` stamina_cost should be a number greater than or equal to zero"

      "time" ->
        raise "Invalid Skill config for `#{skill_config[:name]}` cooldown_ms should be a number greater than or equal to zero"

      "mana" ->
        raise "Invalid Skill config for `#{skill_config[:name]}` mana_cost should be a number greater than or equal to zero"

      _ ->
        raise "Invalid Skill config for `#{skill_config[:name]}` cooldown_mechanism is invalid, should be either `time` or `stamina`"
    end
  end

  defp parse_combo_config(
         %{
           is_combo?: true,
           reset_combo_ms: reset_combo_ms,
           next_skill: nil
         } = skill_config
       )
       when reset_combo_ms >= 0 do
    skill_config
  end

  defp parse_combo_config(
         %{
           is_combo?: true,
           reset_combo_ms: reset_combo_ms,
           next_skill: next_skill
         } = skill_config
       )
       when reset_combo_ms >= 0 do
    Map.put(skill_config, :next_skill, parse_skill_config(next_skill))
  end

  defp parse_combo_config(%{is_combo?: true} = skill_config) do
    raise "Invalid Skill config for `#{skill_config[:name]}` reset_combo_ms is invalid, should be equal or greater than zero"
  end

  defp parse_combo_config(skill_config), do: skill_config

  defp parse_mechanics_config(mechanics_config) do
    Enum.reduce(mechanics_config, [], fn mechanic_config, acc ->
      mechanic = parse_mechanic_config(mechanic_config)
      [mechanic | acc]
    end)
  end

  defp parse_mechanic_config(nil) do
    nil
  end

  defp parse_mechanic_config(mechanic) do
    ## Why do we even need this? Well it happens that some of our fields are represented
    ## as Decimal. To prevent precision loss this struct its converted to a string of the float
    ## which should be read back and converted to Decimal
    ## The not so small problem we have is that our code expects floats so we still need to parse
    ## the strings, but end up with regular floats
    %{
      mechanic
      | angle_between: maybe_to_float(mechanic.angle_between),
        move_by: maybe_to_float(mechanic.move_by),
        radius: maybe_to_float(mechanic.radius),
        range: maybe_to_float(mechanic.range),
        speed: maybe_to_float(mechanic.speed),
        on_arrival_mechanic: parse_mechanic_config(mechanic.on_arrival_mechanic),
        on_explode_mechanics: parse_mechanics_config(mechanic.on_explode_mechanics),
        parent_mechanic: parse_mechanic_config(mechanic.parent_mechanic),
        effect: parse_effect(mechanic.effect),
        on_collide_effect: parse_on_collide_effect(mechanic.on_collide_effect)
    }
  end

  ## Why do we even need this? Well it happens that some of our fields are represented
  ## as Decimal. To prevent precision loss this struct its converted to a string of the float
  ## which should be read back and converted to Decimal
  ## The not so small problem we have is that our code expects floats so we still need to parse
  ## the strings, but end up with regular floats
  defp parse_map_config(map_config) do
    %{
      map_config
      | radius: maybe_to_float(map_config.radius),
        initial_positions: Enum.map(map_config.initial_positions, &parse_position/1),
        square_wall: map_config.square_wall,
        obstacles: Enum.map(map_config.obstacles, &parse_obstacle/1),
        pools: Enum.map(map_config.pools, &parse_entity_values/1),
        bushes: Enum.map(map_config.bushes, &parse_entity_values/1),
        crates: Enum.map(map_config.crates, &parse_entity_values/1)
    }
  end

  defp parse_obstacle(obstacle) do
    obstacle
    |> parse_entity_values()
    |> Map.merge(%{
      statuses_cycle: parse_status_cycle(obstacle.statuses_cycle)
    })
  end

  defp parse_entity_values(entity) do
    %{
      entity
      | position: parse_position(entity.position),
        vertices: Enum.map(entity.vertices, &parse_position/1),
        radius: maybe_to_float(entity.radius)
    }
  end

  defp parse_status_cycle(%{raised: _} = status_cycle) do
    %{status_cycle | raised: parse_raised(status_cycle.raised)}
  end

  defp parse_status_cycle(status_cycle) do
    status_cycle
  end

  defp parse_raised(raised) do
    %{raised | on_activation_mechanics: parse_raised_mechanics_config(raised.on_activation_mechanics)}
  end

  defp parse_raised_mechanics_config(%{polygon_hit: polygon_hit} = mechanics) do
    %{mechanics | polygon_hit: %{polygon_hit | vertices: Enum.map(polygon_hit.vertices, &parse_position/1)}}
  end

  defp parse_on_collide_effect(nil) do
    nil
  end

  defp parse_on_collide_effect(on_collide_effect) do
    %{
      on_collide_effect
      | effect: parse_effect(on_collide_effect.effect)
    }
  end

  defp parse_effect(nil) do
    nil
  end

  defp parse_effect(effect) do
    Map.update!(effect, :effect_mechanics, fn effect_mechanics ->
      Enum.map(effect_mechanics, fn effect_mechanic ->
        %{
          effect_mechanic
          | modifier: maybe_to_float(effect_mechanic.modifier),
            force: maybe_to_float(effect_mechanic.force),
            stat_multiplier: maybe_to_float(effect_mechanic.stat_multiplier)
        }
      end)
    end)
  end

  defp parse_position(%{x: x, y: y}) do
    %{x: maybe_to_float(x), y: maybe_to_float(y)}
  end

  defp parse_game_config(game_config) do
    %{
      game_config
      | power_up_damage_modifier: maybe_to_float(game_config.power_up_damage_modifier),
        power_up_health_modifier: maybe_to_float(game_config.power_up_health_modifier),
        power_up_radius: maybe_to_float(game_config.power_up_radius)
    }
  end

  defp maybe_to_float(nil), do: nil

  defp maybe_to_float(float_integer) when is_integer(float_integer) do
    float_integer / 1.0
  end

  defp maybe_to_float(float) when is_float(float) do
    float
  end

  defp maybe_to_float(float_string) when is_binary(float_string) do
    {float, ""} = Float.parse(float_string)
    float
  end
end
