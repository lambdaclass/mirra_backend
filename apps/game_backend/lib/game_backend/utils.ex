defmodule GameBackend.Utils do
  @moduledoc """
  Helper module
  """

  def get_game_id(:curse_of_mirra), do: 1
  def get_game_id(:champions_of_mirra), do: 2

  def get_daily_rewards_config(),
    do: Application.get_env(:game_backend, :daily_rewards_config) |> Map.get("reward_per_day")

  def transform_to_map_from_ecto_struct(ecto_structs, extra_keys_to_drop \\ [])

  def transform_to_map_from_ecto_struct(ecto_structs, extra_keys_to_drop) when is_list(ecto_structs) do
    Enum.map(ecto_structs, fn ecto_struct ->
      transform_to_map_from_ecto_struct(ecto_struct, extra_keys_to_drop)
    end)
  end

  def transform_to_map_from_ecto_struct(ecto_struct, extra_keys_to_drop) when is_struct(ecto_struct) do
    ecto_struct
    |> Map.from_struct()
    |> Map.drop(
      [
        :__meta__,
        :__struct__,
        :inserted_at,
        :updated_at,
        :id
      ] ++ extra_keys_to_drop
    )
  end
end
