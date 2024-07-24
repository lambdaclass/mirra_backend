defmodule GameBackend.Configuration.Version do
  use GameBackend.Schema
  import Ecto.Changeset

  schema "versions" do
    field(:name, :string)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(version, attrs) do
    version
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
