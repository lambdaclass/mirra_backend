defmodule GameBackend.Users.UserSkin do
  @moduledoc """
  The Currencies context.
  """

use GameBackend.Schema
import Ecto.Changeset

alias GameBackend.Users.User
alias GameBackend.Units.Characters.Skin

@derive {Jason.Encoder,
         only: [
           :user_id,
           :skin_id
         ]}

schema "user_skins" do
  belongs_to(:user, User)
  belongs_to(:skin, Skin)

  timestamps()
end

@doc false
def changeset(character, attrs) do
  character
  |> cast(attrs, [:user_id, :skin_id])
  |> validate_required([:user_id, :skin_id])
end
end
