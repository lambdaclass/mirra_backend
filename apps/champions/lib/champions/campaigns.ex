defmodule Champions.Campaigns do
  @moduledoc """
  Campaigns logic for Champions of Mirra.
  """

  alias GameBackend.Campaigns

  @doc """
  Gets all levels, grouped by campaign and sorted ascendingly.
  """
  def get_campaigns() do
    Campaigns.get_campaigns()
  end

  def get_campaign(campaign_number) do
    Campaigns.get_campaign(campaign_number)
  end

  @doc """
  Inserts a level.
  """
  def insert_level(attrs) do
    Campaigns.insert_level(attrs)
  end

  @doc """
  Get a level by id.
  """
  def get_level(level_id) do
    Campaigns.get_level(level_id)
  end

  @doc """
  Creates levels for Champions of Mirra with a given set of rules, storing them and their units in the DB.

  Rules needed are:
  - `base_level`: the aggregate level of all units in the first level of the campaign
  - `scaler`: used to calculate the aggregate level of the campaign's levels, multiplying the previous level's aggregate by this value
  - `possible_factions`: which factions the randomly generated units can belong to
  - `length`: the length of the campaign.

  Each of the rule maps given represents a campaign, and the number of the campaign (stored in the Level)
  will be equal to the index of its rules in the list (1-based).

  Returns an :ok atom.
  """
  def create_campaigns() do
    Campaigns.create_campaigns()
  end
end
