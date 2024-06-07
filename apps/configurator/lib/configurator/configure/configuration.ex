defmodule Configurator.Configure.Configuration do
  @moduledoc """
  Configuration in DB
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Configurator.Configure.ConfigurationGroup

  schema "configurations" do
    field :name, :string
    field :data, :string
    field :current, :boolean, default: false

    belongs_to :configuration_group, ConfigurationGroup

    timestamps(type: :utc_datetime)
  end

  @required [
    :name,
    :data,
    :current,
    :configuration_group_id
  ]

  @doc false
  def changeset(configuration, attrs) do
    configuration
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> validate_change(:data, &valid_json?/2)
    |> validate_change(:current, &validate_current_configuration/2)
  end

  defp valid_json?(field, data) do
    case Jason.decode(data) do
      {:ok, _} -> []
      {:error, _} -> [{field, "is not valid JSON"}]
    end
  end

  defp validate_current_configuration(field, current) do
    if current do
      []
    else
      [{field, "Cannot set the current configuration as current"}]
    end
  end
end
