defmodule GameBackend.Campaigns.Quest do
  @moduledoc """
  Quest
  """
  alias GameBackend.Campaigns.Campaign

  use GameBackend.Schema
  import Ecto.Changeset

  schema "quests" do
    field(:game_id, :integer)
    field(:name, :string)

    has_many(:campaigns, Campaign)

    timestamps()
  end

  @doc false
  def changeset(quest, attrs \\ %{}) do
    quest
    |> cast(attrs, [:game_id, :name])
    |> cast_assoc(:campaigns)
    |> validate_required([:game_id])
  end
end
