defmodule ChampionsOfMirra.Campaign do
  @moduledoc """
  Documentation for `ChampionsOfMirra.Campaign`.
  """

  def get_campaigns() do
    # case Repo.get_by(Campaign, :game, "championsofmirra") do
    # nil ->
    campaign = create_campaigns()
    # Repo.insert(campaign)
    campaign
    #   campaign -> campaign
    # end
  end

  def create_campaigns() do
    Campaigns.create_campaigns(
      20,
      [
        %{base_level: 5, scaler: 1.5, possible_factions: ["Araban", "Kaline"], length: 10}
        %{base_level: 50, scaler: 1.7, possible_factions: ["Merliot", "Otobi"], length: 20}
      ]
    )
  end
end
