defmodule ChampionsOfMirra.Users do
  @doc """
  Users logic for Champions Of Mirra.
  """

  @game_id 2

  def register(username) do
    {:ok, user} = Users.register_user(%{username: username, game_id: @game_id})

    add_sample_units(user)

    user
  end

  defp add_sample_units(user) do
    characters = Units.all_characters()
    Enum.each(0..4, fn index -> Units.insert_unit(%{character_id: Enum.random(characters).id, user_id: user.id, level: Enum.random(1..5), tier: 1, selected: true, slot: index}) end)
  end
end
