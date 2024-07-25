defmodule ConfiguratorWeb.CharacterController do
  use ConfiguratorWeb, :controller

  alias GameBackend.Units.Characters
  alias GameBackend.Units.Characters.Character

  def index(conn, _params) do
    characters = Characters.get_curse_characters()
    render(conn, :index, characters: characters)
  end

  def new(conn, _params) do
    changeset = Ecto.Changeset.change(%Character{})
    skills = get_curse_skills_by_type()
    render(conn, :new, changeset: changeset, skills: skills)
  end

  def create(conn, %{"character" => character_params}) do
    character_params =
      character_params
      |> Map.put("game_id", GameBackend.Utils.get_game_id(:curse_of_mirra))
      |> Map.put("faction", "curse")

    case Characters.insert_character(character_params) do
      {:ok, character} ->
        conn
        |> put_flash(:success, "Character created successfully.")
        |> redirect(to: ~p"/characters/#{character}")

      {:error, %Ecto.Changeset{} = changeset} ->
        skills = get_curse_skills_by_type()
        render(conn, :new, changeset: changeset, skills: skills)
    end
  end

  def show(conn, %{"id" => id}) do
    character = Characters.get_character(id)
    render(conn, :show, character: character)
  end

  def edit(conn, %{"id" => id}) do
    character = Characters.get_character(id)
    changeset = Ecto.Changeset.change(character)
    skills = get_curse_skills_by_type()
    render(conn, :edit, character: character, changeset: changeset, skills: skills)
  end

  def update(conn, %{"id" => id, "character" => character_params}) do
    character = Characters.get_character(id)

    case Characters.update_character(character, character_params) do
      {:ok, character} ->
        conn
        |> put_flash(:success, "Character updated successfully.")
        |> redirect(to: ~p"/characters/#{character}")

      {:error, %Ecto.Changeset{} = changeset} ->
        skills = get_curse_skills_by_type()
        render(conn, :edit, character: character, changeset: changeset, skills: skills)
    end
  end

  def delete(conn, %{"id" => id}) do
    character = Characters.get_character(id)
    {:ok, _character} = Characters.delete_character(character)

    conn
    |> put_flash(:success, "Character deleted successfully.")
    |> redirect(to: ~p"/characters")
  end

  defp get_curse_skills_by_type() do
    GameBackend.Units.Skills.list_curse_skills()
    |> Enum.group_by(& &1.type)
  end
end
