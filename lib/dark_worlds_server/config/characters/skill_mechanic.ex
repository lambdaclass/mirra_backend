defmodule DarkWorldsServer.Config.Characters.SkillMechanic do
  @moduledoc """
  The SkillMechanic type, corresponding to the SkillMechanicConfigFile Rust enum in skills.rs
  """

  alias DarkWorldsServer.Config.Characters
  alias DarkWorldsServer.Config.Characters.Effect
  alias DarkWorldsServer.Config.Characters.Projectile
  use Ecto.Type

  # Should be something effect names never use
  @nested_list_separator "|"

  def type(), do: :string

  def cast({:give_effect, %{effects_to_give: effects}}), do: {:ok, %{"effects" => effects}}

  def cast({:hit, %{damage: damage, range: range, on_hit_effects: on_hit_effects, cone_angle: cone_angle}}),
    do: {:ok, %{"damage" => damage, "range" => range, "on_hit_effects" => on_hit_effects, "cone_angle" => cone_angle}}

  def cast({:multi_shoot, %{cone_angle: cone_angle, projectile: projectile, count: count}}),
    do: {:ok, %{"cone_angle" => cone_angle, "projectile" => projectile, "count" => count}}

  def cast({:simple_shoot, %{projectile: projectile}}), do: {:ok, %{"projectile" => projectile}}

  def cast(
        {:move_to_target,
         %{
           duration_ms: duration_ms,
           max_range: max_range,
           on_arrival_skills: on_arrival_skills,
           effects_to_remove_on_arrival: effects_to_remove_on_arrival
         }}
      ),
      do: {
        :ok,
        %{
          "duration_ms" => duration_ms,
          "max_range" => max_range,
          "on_arrival_skills" => on_arrival_skills,
          "effects_to_remove_on_arrival" => effects_to_remove_on_arrival
        }
      }

  def load(string), do: {:ok, skill_mechanic_from_string(string)}

  def dump(skill_mechanic), do: {:ok, skill_mechanic_to_string(skill_mechanic)}

  defp skill_mechanic_to_string(skill_mechanic) do
    # Right now we are "preloading" effects and projectiles when preparing the config (GameBackend.parse_config/1).
    # The map functions "un-preload" them. TODO: get rid of this extra step.
    case skill_mechanic do
      %{"effects" => effects} ->
        "GiveEffect,#{effects |> Enum.map_join(@nested_list_separator, & &1.name)}"

      %{"damage" => damage, "range" => range, "cone_angle" => cone_angle, "on_hit_effects" => on_hit_effects} ->
        "Hit,#{damage},#{range},#{cone_angle},#{on_hit_effects |> Enum.map_join(@nested_list_separator, & &1.name)}"

      %{"cone_angle" => cone_angle, "projectile" => projectile, "count" => count} ->
        "MultiShoot,#{cone_angle},#{count},#{projectile.name}"

      %{"projectile" => projectile} ->
        "SimpleShoot,#{projectile.name}"

      %{
        "duration_ms" => duration_ms,
        "max_range" => max_range,
        "on_arrival_skills" => on_arrival_skills,
        "effects_to_remove_on_arrival" => effects_to_remove_on_arrival
      } ->
        "MoveToTarget,#{duration_ms},#{max_range},#{on_arrival_skills |> Enum.map_join(@nested_list_separator, & &1)},#{effects_to_remove_on_arrival |> Enum.map_join(@nested_list_separator, & &1.name)}"
    end
  end

  defp skill_mechanic_from_string(string) do
    case String.split(string, ",") do
      ["GiveEffect", effects] ->
        {:give_effect,
         %{effects: Enum.map(String.split(effects, @nested_list_separator), &Characters.get_effect_by_name/1)}}

      ["Hit", damage, range, cone_angle, on_hit_effects] ->
        {:hit,
         %{
           damage: String.to_integer(damage),
           range: String.to_integer(range),
           cone_angle: String.to_integer(cone_angle),
           on_hit_effects: parse_effects_list(on_hit_effects)
         }}

      ["MultiShoot", cone_angle, count, projectile] ->
        {:multi_shoot,
         %{
           cone_angle: String.to_integer(cone_angle),
           count: String.to_integer(count),
           projectile: Characters.get_projectile_by_name(projectile)
         }}

      ["SimpleShoot", projectile] ->
        {:simple_shoot, %{projectile: Characters.get_projectile_by_name(projectile)}}

      ["MoveToTarget", duration_ms, max_range, on_arrival_skills, effects_to_remove_on_arrival] ->
        {:move_to_target,
         %{
           duration_ms: String.to_integer(duration_ms),
           max_range: String.to_integer(max_range),
           on_arrival_skills: on_arrival_skills |> String.split(@nested_list_separator),
           effects_to_remove_on_arrival: parse_effects_list(effects_to_remove_on_arrival)
         }}

      _ ->
        "Invalid"
    end
  end

  # We need this so that we don't get a [nil] value
  defp parse_effects_list(effects) do
    names = String.split(effects, @nested_list_separator)

    if names == [""] do
      []
    else
      Enum.map(names, &Characters.get_effect_by_name/1)
    end
  end

  def to_backend_map({:give_effect, %{effects: effects}}),
    do: {:give_effect, %{effects_to_give: Enum.map(effects, &Effect.to_backend_map/1)}}

  def to_backend_map({:hit, %{on_hit_effects: [nil]} = hit}),
    do: {:hit, %{hit | on_hit_effects: []}}

  def to_backend_map({:hit, %{on_hit_effects: effects} = hit}),
    do:
      {:hit,
       %{
         hit
         | on_hit_effects: Enum.map(effects, &Effect.to_backend_map/1)
       }}

  def to_backend_map({:multi_shoot, %{projectile: projectile} = multi_shoot}),
    do:
      {:multi_shoot,
       %{
         multi_shoot
         | projectile: Projectile.to_backend_map(projectile)
       }}

  def to_backend_map({:simple_shoot, %{projectile: projectile}}),
    do:
      {:simple_shoot,
       %{
         projectile: Projectile.to_backend_map(projectile)
       }}

  def to_backend_map(
        {:move_to_target,
         %{
           duration_ms: duration_ms,
           max_range: max_range,
           on_arrival_skills: on_arrival_skills,
           effects_to_remove_on_arrival: effects_to_remove_on_arrival
         }}
      ) do
    {:move_to_target,
     %{
       duration_ms: duration_ms,
       max_range: max_range,
       on_arrival_skills: on_arrival_skills,
       effects_to_remove_on_arrival: Enum.map(effects_to_remove_on_arrival, &Effect.to_backend_map/1)
     }}
  end

  def to_backend_map(skill_mechanic), do: skill_mechanic
end
