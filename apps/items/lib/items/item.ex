defmodule Items.Item do
  @moduledoc """
  Items are instances of characters tied to a user.
  """

  use Items.Schema
  import Ecto.Changeset
  alias Users.User
  alias Units.Unit

  @derive {Jason.Encoder, only: [:id, :name, :item_level, :type, :user_id, :unit_id]}
  schema "items" do
    field(:name, :string)
    field(:item_level, :integer)
    field(:type, :string)

    belongs_to(:user, User)
    belongs_to(:unit, Unit)

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name, :item_level, :type, :user_id, :unit_id])
    |> validate_required([:name, :item_level, :type, :user_id])
  end

  def unit_changeset(item, attrs), do: cast(item, attrs, [:unit_id])
  def level_changeset(item, attrs), do: cast(item, attrs, [:level])
end
