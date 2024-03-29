defmodule GameBackend.Items.ItemTemplate do
  @moduledoc """
  ItemTemplates are the template on which items are based.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  schema "item_templates" do
    field(:game_id, :integer)
    field(:name, :string)
    field(:type, :string)

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:game_id, :name, :type])
    |> validate_required([:game_id, :name, :type])
  end
end
