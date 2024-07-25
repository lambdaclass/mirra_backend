defmodule GameBackend.Stores.Store do
  @moduledoc """
  Store is the entity where a User can purchase Items.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Items.ItemTemplate

  schema "stores" do
    field(:game_id, :integer)
    field(:name, :string)
    field(:start_date, :utc_datetime)
    field(:end_date, :utc_datetime)
    has_many(:items, ItemTemplate, on_replace: :delete)

    timestamps()
  end

  @doc false
  def changeset(store, attrs) do
    store
    |> cast(attrs, [:game_id, :name, :start_date, :end_date])
    |> validate_required([:game_id, :name, :end_date])
    |> cast_assoc(:items)
  end
end
