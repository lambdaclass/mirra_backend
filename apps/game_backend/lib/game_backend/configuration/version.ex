defmodule GameBackend.Configuration.Version do
  @moduledoc """
  Version schema.
  """
  use GameBackend.Schema
  import Ecto.Changeset

  schema "versions" do
    field(:name, :string)
    field(:current, :boolean)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(version, attrs) do
    version
    |> cast(attrs, [:name, :current])
    |> validate_required([:name])
  end
end
