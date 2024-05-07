defmodule GameBackend.Units.Skills do
  @moduledoc """
  Operations with skills.
  """

  import Ecto.Query

  alias GameBackend.Units.Skills.Mechanic
  alias GameBackend.Units.Skills.Skill
  alias GameBackend.Repo

  def insert_skill(attrs) do
    %Skill{}
    |> Skill.changeset(attrs)
    |> Repo.insert()
  end

  def update_skill(skill, attrs \\ %{}) do
    skill
    |> Skill.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Inserts all skills into the database.
  If another one already exists with the same name, it updates it instead.
  """
  def upsert_skills(attrs_list) do
    Enum.reduce(attrs_list, Ecto.Multi.new(), fn attrs, multi ->
      # Cannot use Multi.insert because of the embeds_many
      Ecto.Multi.run(multi, attrs.name, fn _, _ ->
        upsert_skill(attrs)
      end)
    end)
    |> Repo.transaction()
  end

  def get_skill_by_name(skill_name) do
    Repo.one(
      from(s in Skill, where: s.name == ^skill_name, preload: [mechanics: [:apply_effects_to, :passive_effects]])
    )
  end

  def upsert_skill(attrs) do
    case get_skill_by_name(attrs.name) do
      nil -> insert_skill(attrs)
      skill -> update_skill(skill, attrs)
    end
  end

  def get_mechanic_detail(mechanic) do
    Enum.find_value(Map.keys(mechanic), fn detail_type ->
      detail_type in Mechanic.mechanic_types() and mechanic[detail_type] != nil
    end)
  end
end
