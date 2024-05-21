defmodule GameBackend.Champions.UserAttributes do
  use GameBackend.Schema, prefix: "champions"
  import Ecto.Changeset

  schema "user_attributes" do
    field(:rank, :integer)
    field(:last_reward_at, :utc_datetime)

    belongs_to :user, GameBackend.Common.DemoUser
    belongs_to :last_transaction, GameBackend.Champions.CurrencyTransaction

    timestamps()
  end

  def changeset(user_attributes, attrs) do
    user_attributes
    |> cast(attrs, [:rank, :last_reward_at, :user_id, :last_transaction_id])
    |> unique_constraint([:rank, :last_reward_at, :user_id])
    |> foreign_key_constraint(:last_transaction_id)
  end
end
