defmodule GameBackend.CurseOfMirra.LevelUpConfiguration do
  @moduledoc """
  GameModeConfiguration schema

  Stores all params related to a specific game mode.
  """
  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.Users.Currencies.CurrencyCost
  alias GameBackend.Configuration.Version

  @derive {Jason.Encoder,
           only: []}

  schema "level_up_configurations" do
    embeds_many :level_info, LevelInfo do
      field(:level, :integer)
      field(:stat_increase_percentage, :integer)

      embeds_many(:currency_costs, CurrencyCost, on_replace: :delete)
    end

    belongs_to(:version, Version)
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(version, attrs) do
    version
    |> cast(attrs, [:version_id])
    |> validate_required([:version_id])
    |> cast_embed(:level_info, with: &level_info_changeset/2)
  end

  def level_info_changeset(level_info, attrs) do
    level_info
    |> cast(attrs, [:level, :stat_increase_percentage])
    |> validate_required([:level, :stat_increase_percentage])
    |> cast_embed(:currency_costs)
  end
end
