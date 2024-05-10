defmodule GameBackend.Quests.DailyQuest do
  @moduledoc """

  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Quests.Quest
  alias GameBackend.Users.User

  schema "daily_quest" do
    belongs_to(:quest, Quest)
    belongs_to(:user, User)

    timestamps()
  end

  @required [
    :quest_id,
    :user_id
  ]

  @permitted [] ++ @required

  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, @permitted)
    |> validate_required(@required)
  end
end
