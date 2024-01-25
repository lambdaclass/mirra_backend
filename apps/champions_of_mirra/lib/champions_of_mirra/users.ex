defmodule ChampionsOfMirra.Users do
  @moduledoc """
  Users logic for Champions Of Mirra.
  """

  alias Users.Currencies

  @game_id 2

  @doc """
  Registers a user. Doesn't handle authentication, users only consist of a unique username for now.

  Sample data is filled to the user for testing purposes.
  """
  def register(username) do
    {:ok, user} = Users.register_user(%{username: username, game_id: @game_id})

    # For testing purposes, we assign some things to our user.
    add_sample_units(user)
    add_sample_items(user)
    add_sample_currencies(user)

    Users.get_user!(user.id)
  end

  @doc """
  Get a user by id.
  """
  def get_user(user_id), do: Users.get_user!(user_id)

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

  defp add_sample_currencies(user) do
    Currencies.add_currency(user.id, Currencies.get_currency_by_name!("Gold").id, 100)
    Currencies.add_currency(user.id, Currencies.get_currency_by_name!("Gems").id, 500)
  end
end
