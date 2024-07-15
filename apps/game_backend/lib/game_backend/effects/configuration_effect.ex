defmodule GameBackend.Effects.ConfigurationEffect do
  @moduledoc """
  ConfigurationEffect schema
  """
  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.Items.ConsumableItem

  @derive {Jason.Encoder, only: [:name, :duration_ms, :remove_on_action, :one_time_application, :mechanics]}
  schema "configuration_effects" do
    field(:name, :string)
    field(:duration_ms, :integer)
    field(:remove_on_action, :boolean, default: false)
    field(:one_time_application, :boolean, default: false)

    ## TODO This relationship will be addressed in another issue: https://github.com/lambdaclass/mirra_backend/issues/771
    field(:mechanics, {:map, :map})

    belongs_to(:consumable_item, ConsumableItem)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(configuration_effect, attrs) do
    configuration_effect
    |> cast(attrs, [:name, :duration_ms, :remove_on_action, :one_time_application, :consumable_item_id, :mechanics])
    |> validate_required([:name, :duration_ms, :remove_on_action, :one_time_application])
  end
end
