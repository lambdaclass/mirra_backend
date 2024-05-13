defmodule GameBackend.Quests.DailyQuest do
  @moduledoc """

  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Quests.Quest
  alias GameBackend.Users.User

  schema "daily_quest" do
    field(:completed_at, :utc_datetime)
    field(:completed, :boolean, default: false)
    belongs_to(:quest, Quest)
    belongs_to(:user, User)

    timestamps()
  end

  @required [
    :quest_id,
    :user_id
  ]

  @permitted [:completed, :completed_at] ++ @required

  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, @permitted)
    |> validate_required(@required)
  end
end
