defmodule ChampionsOfMirra.Users do
  @doc """
  Users logic for Champions Of Mirra.
  """

  alias Users.Repo

  @game_id 2

  def register(username) do
    {:ok, user} = Users.register_user(%{username: username, game_id: @game_id})

    add_sample_units(user)
    add_sample_items(user)

    Users.get_user!(user.id)
  end

  def get_user(user_id), do: Users.get_user!(user_id) |> Repo.preload([:units, :items])

  defp add_sample_units(user) do
    characters = Units.all_characters()

    Enum.each(0..4, fn index ->
      Units.insert_unit(%{
        character_id: Enum.random(characters).id,
        user_id: user.id,
        unit_level: Enum.random(1..5),
        tier: 1,
        selected: true,
        slot: index
      })
    end)
  end

  defp add_sample_items(user) do
    Items.get_item_templates()
    |> Enum.each(fn template ->
      Items.insert_item(%{user_id: user.id, template_id: template.id, level: Enum.random(1..5)})
    end)
  end
end
