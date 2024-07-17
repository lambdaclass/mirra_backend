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
    ## TODO This relationship will be addressed in another issue: https://github.com/lambdaclass/mirra_backend/issues/771

    attrs =
      if valid_json?(attrs["mechanics"]) do
        mechanics = Jason.decode!(attrs["mechanics"] || "{}")
        Map.put(attrs, "mechanics", mechanics)
      else
        attrs
      end
      |> IO.inspect()

    configuration_effect
    |> cast(attrs, [:name, :duration_ms, :remove_on_action, :one_time_application, :consumable_item_id, :mechanics])
    |> validate_required([:name, :duration_ms, :remove_on_action, :one_time_application])
    |> IO.inspect(label: :changeset)
  end

  defp valid_json?(nil), do: false

  defp valid_json?(data) do
    IO.inspect(data, label: :data)

    case Jason.decode(data) |> IO.inspect() do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end
end
