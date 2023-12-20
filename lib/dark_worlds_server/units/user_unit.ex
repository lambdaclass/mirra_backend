defmodule DarkWorldsServer.Units.UserUnit do
  @moduledoc """
  The User-Unit association intermediate table.
  """
  alias DarkWorldsServer.Accounts.User
  alias DarkWorldsServer.Units.Unit

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_units" do
    belongs_to(:user, User)
    belongs_to(:unit, Unit)

    timestamps()
  end

  @doc false
  def changeset(user_unit, attrs) do
    user_unit
    |> cast(attrs, [:user_id, :unit_id])
    |> validate_required([:user_id, :unit_id])
  end
end
