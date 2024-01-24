defmodule Items.Item do
  @moduledoc """
  Items are instances of ItemTemplates tied to a user that can be equipped to units.
  """

  use Items.Schema
  import Ecto.Changeset

  alias Items.ItemTemplate
  alias Users.User
  alias Units.Unit

  @derive {Jason.Encoder, only: [:id, :level, :template_id, :user_id, :unit_id]}
  schema "items" do
    field(:level, :integer)

    belongs_to(:template, ItemTemplate)
    belongs_to(:user, User)
    belongs_to(:unit, Unit)
    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:level, :template_id, :user_id, :unit_id])
    |> validate_required([:level, :template_id, :user_id])
  end

  @doc false
  def unit_changeset(item, attrs), do: cast(item, attrs, [:unit_id])

  @doc false
  def level_up_changeset(item), do: cast(item, %{level: item.level + 1}, [:level])
end
