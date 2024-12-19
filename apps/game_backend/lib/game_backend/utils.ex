defmodule GameBackend.Utils do
  @moduledoc """
  Helper module
  """

  import Ecto.Query

  def get_game_id(:curse_of_mirra), do: 1
  def get_game_id(:champions_of_mirra), do: 2

  # TODO: Remove this after fixing Autobattler seeds. Did this to mark version_id as required for skills
  def get_autobattler_version!() do
    GameBackend.Repo.one!(
      from(
        v in GameBackend.Configuration.Version,
        where: v.name == "autobattler",
        select: v.id
      )
    )
  end

  def get_daily_rewards_config(),
    do: Application.get_env(:game_backend, :daily_rewards_config) |> Map.get("reward_per_day")
end
