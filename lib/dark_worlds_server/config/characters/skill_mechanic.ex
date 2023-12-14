defmodule DarkWorldsServer.Config.Characters.SkillMechanic do
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

  def cast({:move_to_target, %{duration_ms: duration_ms, max_range: max_range}}),
    do: {:ok, %{"duration_ms" => duration_ms, "max_range" => max_range}}

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

      %{"duration_ms" => duration_ms, "max_range" => max_range} ->
        "MoveToTarget,#{duration_ms},#{max_range}"
    end
  end

  defp skill_mechanic_from_string(string) do
    case String.split(string, ",") do
      ["GiveEffect", effects] ->
        %{effects: String.split(effects, @nested_list_separator)}

      ["Hit", damage, range, cone_angle, on_hit_effects] ->
        %{
          damage: String.to_integer(damage),
          range: String.to_integer(range),
          cone_angle: String.to_integer(cone_angle),
          on_hit_effects: String.split(on_hit_effects, @nested_list_separator)
        }

      ["MultiShoot", cone_angle, count, projectile] ->
        %{
          cone_angle: String.to_integer(cone_angle),
          count: String.to_integer(count),
          projectile: projectile
        }

      ["SimpleShoot", projectile] ->
        %{projectile: projectile}

      ["MoveToTarget", duration_ms, max_range] ->
        %{duration_ms: String.to_integer(duration_ms), max_range: String.to_integer(max_range)}

      _ ->
        "Invalid"
    end
  end
end
