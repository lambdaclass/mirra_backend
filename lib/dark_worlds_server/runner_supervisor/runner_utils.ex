defmodule DarkWorldsServer.RunnerUtils do
  def action_skill_to_key("BasicAttack"), do: "1"
  def action_skill_to_key("Skill1"), do: "2"
  def action_skill_to_key(:skill_1), do: "2"
  def action_skill_to_key(:skill_2), do: "3"
  def action_skill_to_key(:skill_3), do: "4"
  def action_skill_to_key(:skill_4), do: "5"

  def extract_and_convert_params(params) do
    Map.from_struct(params)
    |> Map.drop([:__unknown_fields__])
    |> Enum.map(fn {key, value} -> {to_string(key), to_string(value)} end)
    |> Map.new()
  end
end
