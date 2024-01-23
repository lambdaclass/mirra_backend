defmodule ChampionsOfMirra do
  @moduledoc """
  Documentation for `ChampionsOfMirra`.
  """

  def process(:get_campaigns) do
    ChampionsOfMirra.Campaign.get_campaigns()
  end
end
