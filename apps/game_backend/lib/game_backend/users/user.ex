defmodule GameBackend.Users.User do
  @moduledoc """
  Users.
  """

  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.Items.Item
  alias GameBackend.Units.Unit
  alias GameBackend.Users.Currencies.UserCurrency

  @derive {Jason.Encoder,
           only: [:id, :username, :current_campaign, :current_level, :currencies, :units, :items]}
  schema "users" do
    field(:game_id, :integer)
    field(:username, :string)
    field(:current_campaign, :integer, default: 1)
    field(:current_level, :integer, default: 1)

    has_many(:currencies, UserCurrency)
    has_many(:units, Unit)
    has_many(:items, Item)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:game_id, :username, :current_campaign, :current_level])
    |> unique_constraint([:game_id, :username])
    |> validate_required([:game_id, :username])
  end
end
