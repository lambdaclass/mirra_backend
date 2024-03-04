defmodule Configurator.Configure.Configuration do
  use Ecto.Schema
  import Ecto.Changeset

  schema "configurations" do
    field :data, Configurator.Ecto.JsonBlob
    field :is_default, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(configuration, attrs) do
    configuration
    |> cast(attrs, [:data, :is_default])
    |> validate_required([:data, :is_default])
  end
end
