defmodule ConfiguratorWeb.CharacterController do
  use ConfiguratorWeb, :controller

  alias GameBackend.Units.Characters
  alias GameBackend.Units.Characters.Character
  alias GameBackend.Configuration
  alias GameBackend.Utils

  def index(conn, %{"id" => version_id}) do
    characters = Characters.get_curse_characters_by_version(version_id)
    render(conn, :index, characters: characters, version_id: version_id)
  end

  def new(conn, %{"id" => version_id}) do
    changeset = Ecto.Changeset.change(%Character{})
    version = Configuration.get_version!(version_id)
    skills = Utils.list_curse_skills_by_version_grouped_by_type(version.id)
    render(conn, :new, changeset: changeset, skills: skills, version: version)
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
        |> redirect(to: ~p"/versions/#{character.version_id}/characters/#{character}")

      {:error, %Ecto.Changeset{} = changeset} ->
        version = Configuration.get_version!(character_params["version_id"])
        skills = Utils.list_curse_skills_by_version_grouped_by_type(version.id)
        render(conn, :new, changeset: changeset, skills: skills, version: version)
    end
  end

  def show(conn, %{"id" => id}) do
    character = Characters.get_character(id)
    version = Configuration.get_version!(character.version_id)
    render(conn, :show, character: character, version: version)
  end

  def edit(conn, %{"id" => id}) do
    character = Characters.get_character(id)
    changeset = Ecto.Changeset.change(character)
    version = Configuration.get_version!(character.version_id)
    skills = Utils.list_curse_skills_by_version_grouped_by_type(version.id)
    render(conn, :edit, character: character, changeset: changeset, skills: skills, version: version)
  end

  def update(conn, %{"id" => id, "character" => character_params}) do
    character = Characters.get_character(id)

    case Characters.update_character(character, character_params) do
      {:ok, character} ->
        conn
        |> put_flash(:success, "Character updated successfully.")
        |> redirect(to: ~p"/versions/#{character.version_id}/characters/#{character}")

      {:error, %Ecto.Changeset{} = changeset} ->
        version = Configuration.get_version!(character.version_id)
        skills = Utils.list_curse_skills_by_version_grouped_by_type(version.id)
        render(conn, :edit, character: character, changeset: changeset, skills: skills, version: version)
    end
  end

  def delete(conn, %{"id" => id}) do
    character = Characters.get_character(id)
    version_id = character.version_id
    {:ok, _character} = Characters.delete_character(character)

    conn
    |> put_flash(:success, "Character deleted successfully.")
    |> redirect(to: ~p"/versions/#{version_id}/characters")
  end
end
