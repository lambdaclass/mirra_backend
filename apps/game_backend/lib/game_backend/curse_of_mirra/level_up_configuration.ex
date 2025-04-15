defmodule GameBackend.CurseOfMirra.LevelUpConfiguration do
  @moduledoc """
  LevelUpConfiguration schema

  Stores the cost requirements and upgrades given by each level
  """
  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.CurseOfMirra.LevelInfo
  alias GameBackend.Configuration.Version

  schema "level_up_configurations" do
    embeds_many(:level_info, LevelInfo)

    belongs_to(:version, Version)
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(version, attrs) do
    version
    |> cast(attrs, [:version_id])
    |> validate_required([:version_id])
    |> cast_embed(:level_info)
  end
end
