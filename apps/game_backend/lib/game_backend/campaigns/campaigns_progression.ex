defmodule GameBackend.Campaigns.Campaigns_Progression do
  @moduledoc """
  Campaigns Progression
  """

  use GameBackend.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id]}
  schema "campaigns_progression" do
    field(:game_id, :integer)
    field(:user_id, :integer)
    field(:campaign_id, :integer)
    field(:campaign_number, :integer)
    field(:level_id, :integer)
    field(:level_number, :integer)

    timestamps()
  end

  @doc false
  def changeset(campaigns_progression, attrs \\ %{}) do
    campaigns_progression
    |> cast(attrs, [:game_id, :user_id, :campaign_id, :level_id])
    |> validate_required([:game_id, :user_id, :campaign_id, :level_id])
  end
end
