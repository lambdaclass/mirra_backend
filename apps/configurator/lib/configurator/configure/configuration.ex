defmodule Configurator.Configure.Configuration do
  @moduledoc """
  Configuration in DB
  """
  use Configurator.Schema
  import Ecto.Changeset

  schema "configurations" do
    field :data, :string
    field :is_default, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(configuration, attrs) do
    configuration
    |> cast(attrs, [:data, :is_default])
    |> validate_required([:data, :is_default])
    |> validate_change(:data, &valid_json?/2)
  end

  defp valid_json?(field, data) do
    case Jason.decode(data) do
      {:ok, _} -> []
      {:error, _} -> [{field, "is not valid JSON"}]
    end
  end
end
