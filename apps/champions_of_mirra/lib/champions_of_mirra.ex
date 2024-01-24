defmodule ChampionsOfMirra do
  @moduledoc """
  Champions of Mirra request handler.
  """

  def process(:get_campaigns) do
    ChampionsOfMirra.Campaign.get_campaigns()
  end

  def process(:create_user, username) do
    ChampionsOfMirra.Users.register(username)
  end
end
