defmodule GameBackend.Campaigns do
  @moduledoc """
  Operations with Campaigns and Levels.
  """

  import Ecto.Query
  alias GameBackend.Repo
  alias GameBackend.Campaigns.Level

  @doc """
  Gets all levels, grouped by campaign and sorted ascendingly.
  """
  def get_campaigns() do
    campaigns =
      Repo.all(from(l in Level))
      |> Repo.preload(units: [:character, :items])
      |> Enum.sort(fn l1, l2 -> l1.level_number < l2.level_number end)
      |> Enum.group_by(fn l -> l.campaign end)
      |> Map.values()

    if Enum.empty?(campaigns), do: {:error, :no_campaigns}, else: campaigns
  end

  def get_campaign(campaign_number) do
    campaign =
      Repo.all(from(l in Level, where: l.campaign == ^campaign_number))
      |> Repo.preload(units: [:character, :items])

    case campaign do
      [] -> {:error, :not_found}
      campaign -> campaign
    end
  end

  @doc """
  Inserts a level.
  """
  def insert_level(attrs) do
    %Level{}
    |> Level.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get a level by id.
  """
  def get_level(level_id) do
    Repo.get(Level, level_id) |> Repo.preload(units: :items, units: :character)
  end

  def get_campaign_progression(user_id, campaign_id) do
    Repo.get_by(GameBackend.Campaigns.Campaigns_Progression,
      user_id: user_id,
      campaign_id: campaign_id
    )
  end
end
