defmodule ConfiguratorWeb.SkillController do
  use ConfiguratorWeb, :controller

  alias GameBackend.Units.Skills
  alias GameBackend.Units.Skills.Mechanic
  alias GameBackend.Units.Skills.Skill
  alias GameBackend.Utils
  alias GameBackend.Configuration

  def index(conn, _params) do
    skills = Skills.list_curse_skills()
    render(conn, :index, skills: skills)
  end

  def new(conn, _params) do
    changeset = Skills.change_skill(%Skill{mechanics: [%Mechanic{}]})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"skill" => skill_params}) do
    skill_params = Map.put(skill_params, "game_id", Utils.get_game_id(:curse_of_mirra))

    case Skills.insert_skill(skill_params) do
      {:ok, skill} ->
        conn
        |> put_flash(:info, "Skill created successfully.")
        |> redirect(to: ~p"/skills/#{skill}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    skill = Skills.get_skill!(id)
    render(conn, :show, skill: skill)
  end

  def edit(conn, %{"id" => id}) do
    skill = Skills.get_skill!(id)
    changeset = Skills.change_skill(skill)
    render(conn, :edit, skill: skill, changeset: changeset)
  end

  def update(conn, %{"id" => id, "skill" => skill_params}) do
    skill = Skills.get_skill!(id)

    skill_params =
      update_in(skill_params, ["mechanics", "0", "vertices"], fn vertices -> Jason.decode!(vertices) end)

    case Skills.update_skill(skill, skill_params) do
      {:ok, skill} ->
        conn
        |> put_flash(:info, "Skill updated successfully.")
        |> redirect(to: ~p"/skills/#{skill}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, skill: skill, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    skill = Skills.get_skill!(id)

    case Skills.delete_skill(skill) do
      {:error, %{errors: [characters: {_, [constraint: :foreign, constraint_name: "characters_basic_skill_id_fkey"]}]}} ->
        conn
        |> put_flash(:error, "Skill being used by a Character.")
        |> redirect(to: ~p"/skills/#{skill}")

      {:error, _changeset} ->
        conn
        |> put_flash(:info, "Something went wrong.")
        |> redirect(to: ~p"/skills/#{skill}")

      {:ok, _skill} ->
        conn
        |> put_flash(:success, "Skill deleted successfully.")
        |> redirect(to: ~p"/skills")
    end
  end
end
