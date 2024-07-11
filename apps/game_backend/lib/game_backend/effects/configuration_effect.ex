defmodule GameBackend.Effects.ConfigurationEffect do
  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.Items.ConsumableItem

  schema "configuration_effects" do
    field(:name, :string)
    field(:duration_ms, :integer)
    field(:remove_on_action, :boolean, default: false)
    field(:one_time_application, :boolean, default: false)

    belongs_to(:effect, ConsumableItem)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(configuration_effect, attrs) do
    configuration_effect
    |> cast(attrs, [:name, :duration_ms, :remove_on_action, :one_time_application])
    |> validate_required([:name, :duration_ms, :remove_on_action, :one_time_application])
  end
end