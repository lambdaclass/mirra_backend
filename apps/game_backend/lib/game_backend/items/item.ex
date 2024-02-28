defmodule GameBackend.Items.Item do
  @moduledoc """
  Items are instances of ItemTemplates tied to a user that can be equipped to units.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Items.ItemTemplate
  alias GameBackend.Users.User
  alias GameBackend.Units.Unit

  @derive {Jason.Encoder, only: [:id, :level, :template, :user_id, :unit_id]}
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
  def equip_changeset(item, unit_id), do: cast(item, %{unit_id: unit_id}, [:unit_id])

  @doc false
  def level_up_changeset(item, attrs), do: cast(item, attrs, [:level])
end
