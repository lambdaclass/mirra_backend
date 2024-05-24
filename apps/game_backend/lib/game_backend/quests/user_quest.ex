defmodule GameBackend.Quests.UserQuest do
  @moduledoc """
    Relation between users and quests, will determine if a quest is completed or no
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Quests.Quest
  alias GameBackend.Users.User

  schema "user_quest" do
    field(:completed_at, :utc_datetime)
    field(:status, :string)
    belongs_to(:quest, Quest)
    belongs_to(:user, User)

    timestamps()
  end

  @required [
    :quest_id,
    :user_id,
    :status
  ]

  @permitted [:completed_at] ++ @required

  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> validate_inclusion(:status, ["available", "completed", "rerolled", "lost"])
  end
end
