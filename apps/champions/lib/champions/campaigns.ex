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

  def get_campaign(campaign_id) do
    Campaigns.get_campaign(campaign_id)
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
    case Campaigns.get_level(level_id) do
      nil -> {:error, :not_found}
      level -> level
    end
  end
end
