defmodule ChampionsOfMirra do
  @moduledoc """
  Champions of Mirra request handler.
  """

  ###########
  ## USERS ##
  ###########

  def process_users(:create_user, username) do
    ChampionsOfMirra.Users.register(username)
  end

  def process_users(:get_user, user_id) do
    ChampionsOfMirra.Users.get_user(user_id)
  end

  #############
  ## BATTLES ##
  #############

  def process_battles(:get_campaigns) do
    ChampionsOfMirra.Campaigns.get_campaigns()
  end

  def process_battles(:get_level, id) do
    ChampionsOfMirra.Campaigns.get_level(id)
  end

  def process_battles(:fight_level, id) do
    ChampionsOfMirra.Campaigns.fight_level(id)
  end

  # def process(:battle, user_1, user_2) do
  #   ChampionsOfMirra.Battle.pvp_battle(user_1, user_2)
  # end
end
