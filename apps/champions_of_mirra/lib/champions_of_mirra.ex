defmodule ChampionsOfMirra do
  @moduledoc """
  Champions of Mirra request handler.
  """

  ###########
  ## USERS ##
  ###########

  def process(:create_user, username) do
    ChampionsOfMirra.Users.register(username)
  end

  #############
  ## BATTLES ##
  #############

  def process(:get_campaigns) do
    ChampionsOfMirra.Campaigns.get_campaigns()
  end

  def process(:level, id) do
    ChampionsOfMirra.Campaigns.get_level(id)
  end

  def process(:fight_level, id) do
    ChampionsOfMirra.Campaigns.fight_level(id)
  end

  # def process(:battle, user_1, user_2) do
  #   ChampionsOfMirra.Battle.pvp_battle(user_1, user_2)
  # end
end
