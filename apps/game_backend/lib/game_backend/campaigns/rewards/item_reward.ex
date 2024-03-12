defmodule GameBackend.Campaigns.Rewards.ItemReward do
  @moduledoc """
  The representation of a level reward that gives an item to the user.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Items.ItemTemplate
  alias GameBackend.Campaigns.Level

  schema "item_rewards" do
    belongs_to(:level, Level)
    belongs_to(:item_template, ItemTemplate)
    field(:amount, :integer)

    timestamps()
  end

  @doc false
  def changeset(item_reward, attrs) do
    item_reward
    |> cast(attrs, [:item_template_id, :level_id, :amount])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> validate_required([:amount])
  end
end
