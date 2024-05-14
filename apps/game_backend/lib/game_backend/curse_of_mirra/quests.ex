defmodule GameBackend.CurseOfMirra.Quests do
  @moduledoc """
    Module to work with quest logic
  """
  alias GameBackend.Quests.DailyQuest
  alias GameBackend.Repo
  alias GameBackend.Quests.Quest
  alias Ecto.Multi
  import Ecto.Query

  @doc """
  Get a %Quest{} by the config_id field

  ## Examples

      iex>get_quest_by_config_id(4)
      %Quest{config_id: 4}

  """
  def get_quest_by_config_id(quest_config_id) do
    Repo.get_by(Quest, config_id: quest_config_id)
  end

  @doc """
  Get all %Quest{} by the type field

  ## Examples

      iex>get_quest_by_config_id("daily")
      [%Quest{type: "daily"}]
  """
  def get_quests_by_type(type) do
    q =
      from(qd in Quest,
        where: qd.type == ^type
      )

    Repo.all(q)
  end

  @doc """
  Run the quest changeset with the given attrs
  Return %Changeset{}

  ## Examples

      iex>change_quest(quest, attrs)
      %Changeset{}

  """
  def change_quest(quest, attrs) do
    Quest.changeset(quest, attrs)
  end

  @doc """
  Insert or update config quests present in the "quests_descriptions.json" file
  """
  def upsert_quests(quests_params) do
    Enum.reduce(quests_params, Multi.new(), fn quest_param, multi ->
      case get_quest_by_config_id(quest_param.config_id) do
        nil ->
          changeset = change_quest(%Quest{}, quest_param)
          Multi.insert(multi, quest_param.config_id, changeset)

        quest ->
          changeset = change_quest(quest, quest_param)
          Multi.update(multi, quest_param.config_id, changeset)
      end
    end)
    |> Repo.transaction()
  end

  def add_quest_to_user_id(user_id, amount, type) do
    available_quests =
      get_quests_by_type(type)
      |> Enum.shuffle()

    {multi, _quests} =
      Enum.reduce(1..amount, {Multi.new(), available_quests}, fn
        _index, {multi, []} ->
          {multi, []}

        _index, {multi, [quest | next_quests]} ->
          attrs = %{
            user_id: user_id,
            quest_id: quest.id
          }

          changeset = DailyQuest.changeset(%DailyQuest{}, attrs)

          multi = Multi.insert(multi, {:insert_user_quest, user_id, quest.id}, changeset)

          {multi, next_quests}
      end)

    Repo.transaction(multi)
  end
end
