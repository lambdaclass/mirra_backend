defmodule GameBackend.Quests.UserDailyQuest do
  @moduledoc """

  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Quests.QuestDescription
  alias GameBackend.Users.User

  schema "user_daily_quest" do
    field(:target, :integer)
    field(:progress, :integer)

    belongs_to(
      :quest_description,
      QuestDescription
    )

    belongs_to(:user, User)

    timestamps()
  end

  @required [
    :quest_description_id,
    :user_id,
    :target,
    :progress
  ]

  @permitted [] ++ @required

  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, @permitted)
    |> validate_required(@required)
  end
end
