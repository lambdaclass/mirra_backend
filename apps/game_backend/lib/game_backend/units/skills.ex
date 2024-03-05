defmodule GameBackend.Units.Skills do
  alias GameBackend.Units.Skill

  @doc """
  Operations with skills.
  """

  import Ecto.Query

  alias GameBackend.Repo

  def insert_skill(attrs) do
    %Skill{}
    |> Skill.changeset(attrs)
    |> Repo.insert()
  end

  def get_skill_id_by_name(skill_name) do
    Repo.one(from(s in Skill, where: s.name == ^skill_name, select: s.id))
  end
end
