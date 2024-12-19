defmodule ConfiguratorWeb.SkillController do
  use ConfiguratorWeb, :controller

  alias GameBackend.Units.Skills
  alias GameBackend.Units.Skills.Mechanic
  alias GameBackend.Units.Skills.Skill
  alias GameBackend.Utils
  alias GameBackend.Configuration

  def index(conn, %{"id" => version_id}) do
    skills = Skills.list_curse_skills_by_version(version_id)
    render(conn, :index, skills: skills, version_id: version_id)
  end

  def new(conn, %{"id" => version_id}) do
    changeset = Skills.change_skill(%Skill{mechanics: [%Mechanic{}]})
    version = Configuration.get_version!(version_id)
    render(conn, :new, changeset: changeset, version: version)
  end

  def create(conn, %{"skill" => skill_params}) do
    skill_params = Map.put(skill_params, "game_id", Utils.get_game_id(:curse_of_mirra))

    case Skills.insert_skill(skill_params) do
      {:ok, skill} ->
        conn
        |> put_flash(:info, "Skill created successfully.")
        |> redirect(to: ~p"/versions/#{skill.version_id}/skills/#{skill}")

      {:error, %Ecto.Changeset{} = changeset} ->
        version = Configuration.get_version!(skill_params["version_id"])
        render(conn, :new, changeset: changeset, version: version)
    end
  end

  def show(conn, %{"id" => id}) do
    skill = Skills.get_skill!(id)
    version = Configuration.get_version!(skill.version_id)
    render(conn, :show, skill: skill, version: version)
  end

  def edit(conn, %{"id" => id}) do
    skill = Skills.get_skill!(id)
    changeset = Skills.change_skill(skill)
    version = Configuration.get_version!(skill.version_id)
    render(conn, :edit, skill: skill, changeset: changeset, version: version)
  end

  def update(conn, %{"id" => id, "skill" => skill_params}) do
    skill = Skills.get_skill!(id)

    skill_params =
      update_in(skill_params, ["mechanics", "0", "vertices"], fn vertices -> Jason.decode!(vertices) end)

    case Skills.update_skill(skill, skill_params) do
      {:ok, skill} ->
        conn
        |> put_flash(:info, "Skill updated successfully.")
        |> redirect(to: ~p"/versions/#{skill.version_id}/skills/#{skill}")

      {:error, %Ecto.Changeset{} = changeset} ->
        version = Configuration.get_version!(skill.version_id)
        render(conn, :edit, skill: skill, changeset: changeset, version: version)
    end
  end

  def delete(conn, %{"id" => id}) do
    skill = Skills.get_skill!(id)
    version_id = skill.version_id

    case Skills.delete_skill(skill) do
      {:error, %{errors: [characters: {_, [constraint: :foreign, constraint_name: "characters_basic_skill_id_fkey"]}]}} ->
        conn
        |> put_flash(:error, "Skill being used by a Character.")
        |> redirect(to: ~p"/versions/#{version_id}/skills/#{skill}")

      {:error, _changeset} ->
        conn
        |> put_flash(:info, "Something went wrong.")
        |> redirect(to: ~p"/versions/#{version_id}/skills/#{skill}")

      {:ok, _skill} ->
        conn
        |> put_flash(:success, "Skill deleted successfully.")
        |> redirect(to: ~p"/versions/#{version_id}/skills")
    end
  end
end
