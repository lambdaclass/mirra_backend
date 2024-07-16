defmodule Arena.Configuration do
  @moduledoc """
  Module in charge of configuration related things
  """

  def get_character_config(name, config) do
    Enum.find(config.characters, fn character -> character.name == name end)
  end

  def get_game_config() do
    {:ok, config_json} =
      Application.app_dir(:arena, "priv/config.json")
      |> File.read()

    config = Jason.decode!(config_json, [{:keys, :atoms}])
    skills = parse_skills_config(config.skills)
    characters = parse_characters_config(get_characters_config(), skills)
    client_config = get_client_config()
    game_config = get_game_configuration()
    map_config = parse_map_confg(get_map_config())

    %{config | skills: skills}
    |> Map.put(:characters, characters)
    |> Map.put(:game, game_config)
    |> Map.put(:map, map_config)
    |> Map.put(:client_config, client_config)
  end

  defp get_map_config() do
    gateway_url = Application.get_env(:arena, :gateway_url)

    {:ok, payload} =
      Finch.build(:get, "#{gateway_url}/curse/configuration/map", [{"content-type", "application/json"}])
      |> Finch.request(Arena.Finch)

    Jason.decode!(payload.body, [{:keys, :atoms}])
  end

  defp get_client_config() do
    {:ok, config_json} =
      Application.app_dir(:arena, "priv/client_config.json")
      |> File.read()

    Jason.decode!(config_json, [{:keys, :atoms}])
  end

  defp get_characters_config() do
    gateway_url = Application.get_env(:arena, :gateway_url)

    {:ok, payload} =
      Finch.build(:get, "#{gateway_url}/curse/configuration/characters", [{"content-type", "application/json"}])
      |> Finch.request(Arena.Finch)

    Jason.decode!(payload.body, [{:keys, :atoms}])
  end

  defp get_game_configuration() do
    gateway_url = Application.get_env(:arena, :gateway_url)

    {:ok, payload} =
      Finch.build(:get, "#{gateway_url}/curse/configuration/game", [{"content-type", "application/json"}])
      |> Finch.request(Arena.Finch)

    Jason.decode!(payload.body, [{:keys, :atoms}])
  end

  defp parse_skills_config(skills_config) do
    Enum.reduce(skills_config, [], fn skill_config, skills ->
      skill = parse_skill_config(skill_config)
      [skill | skills]
    end)
  end

  defp parse_skill_config(%{cooldown_mechanism: "stamina", stamina_cost: cost} = skill_config) when cost >= 0 do
    mechanics = parse_mechanics_config(skill_config.mechanics)
    %{skill_config | mechanics: mechanics}
  end

  defp parse_skill_config(%{cooldown_mechanism: "time", cooldown_ms: cooldown} = skill_config) when cooldown >= 0 do
    mechanics = parse_mechanics_config(skill_config.mechanics)
    %{skill_config | mechanics: mechanics}
  end

  defp parse_skill_config(skill_config) do
    case skill_config.cooldown_mechanism do
      "stamina" ->
        raise "Invalid Skill config for `#{skill_config[:name]}` stamina_cost should be a number greater than or equal to zero"

      "time" ->
        raise "Invalid Skill config for `#{skill_config[:name]}` cooldown_ms should be a number greater than or equal to zero"

      _ ->
        raise "Invalid Skill config for `#{skill_config[:name]}` cooldown_mechanism is invalid, should be either `time` or `stamina`"
    end
  end

  defp parse_mechanics_config(mechanics_config) do
    Enum.reduce(mechanics_config, [], fn mechanic_config, acc ->
      mechanic = parse_mechanic_config(mechanic_config)
      [mechanic | acc]
    end)
  end

  defp parse_mechanic_config(mechanic) when map_size(mechanic) > 1 do
    raise "Config has mechanic with 2 values: #{inspect(mechanic)}"
  end

  defp parse_mechanic_config(mechanic) do
    Map.to_list(mechanic)
    |> Enum.map(&parse_mechanic_fields/1)
    |> hd()
  end

  defp parse_mechanic_fields({:leap, attrs}) do
    {:leap, %{attrs | on_arrival_mechanic: parse_mechanic_config(attrs.on_arrival_mechanic)}}
  end

  defp parse_mechanic_fields({name, %{on_explode_mechanics: on_explode_mechanics} = attrs}) do
    {name,
     %{
       attrs
       | on_explode_mechanics: parse_mechanic_config(on_explode_mechanics)
     }}
  end

  defp parse_mechanic_fields(mechanic) do
    mechanic
  end

  defp parse_characters_config(characters, config_skills) do
    Enum.map(characters, fn character ->
      character_skills =
        Enum.map(character.skills, fn {skill_key, skill_name} ->
          skill = find_skill!(skill_name, config_skills)
          {:erlang.atom_to_binary(skill_key), skill}
        end)
        |> Map.new()

      %{character | skills: character_skills}
    end)
  end

  defp find_skill!(skill_name, skills) do
    skill = Enum.find(skills, fn skill -> skill.name == skill_name end)

    ## This is a sanity check when loading the config
    if skill == nil do
      raise "Skill #{inspect(skill_name)} does not exist in config"
    else
      skill
    end
  end

  ## Why do we even need this? Well it happens that some of our fields are represented
  ## as Decimal. To prevent precision loss this struct its converted to a string of the float
  ## which should be read back and converted to Decimal
  ## The not so small problem we have is that our code expects floats so we still need to parse
  ## the strings, but end up with regular floats
  defp parse_map_confg(map_config) do
    %{
      map_config
      | radius: maybe_to_float(map_config.radius),
        initial_positions: Enum.map(map_config.initial_positions, &parse_position/1),
        obstacles: Enum.map(map_config.obstacles, &parse_obstacle/1)
    }
  end

  defp parse_obstacle(obstacle) do
    %{
      obstacle
      | position: parse_position(obstacle.position),
        vertices: Enum.map(obstacle.vertices, &parse_position/1),
        radius: maybe_to_float(obstacle.radius),
        statuses_cycle: parse_status_cycle(obstacle.statuses_cycle)
    }
  end

  defp parse_status_cycle(%{raised: _} = status_cycle) do
    %{ status_cycle | raised: parse_raised(status_cycle.raised) }
  end

  defp parse_status_cycle(status_cycle) do
    status_cycle
  end

  defp parse_raised(raised) do
    %{ raised | on_activation_mechanics: parse_raised_mechanics_config(raised.on_activation_mechanics) }
  end

  defp parse_raised_mechanics_config(%{polygon_hit: polygon_hit} = mechanics) do
    %{mechanics | polygon_hit: %{polygon_hit | vertices: Enum.map(polygon_hit.vertices, &parse_position/1)}}
  end

  defp parse_position(%{x: x, y: y}) do
    %{x: maybe_to_float(x), y: maybe_to_float(y)}
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
