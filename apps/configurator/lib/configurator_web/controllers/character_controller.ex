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
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"character" => character_params}) do
    # TODO This should be removed once we have the skills relationship, issue: https://github.com/lambdaclass/mirra_backend/issues/717
    skills = Jason.decode!(character_params["skills"])

    character_params =
      Map.put(character_params, "skills", skills)
      |> Map.put("game_id", GameBackend.Utils.get_game_id(:curse_of_mirra))
      |> Map.put("faction", "curse")

    case Characters.insert_character(character_params) do
      {:ok, character} ->
        conn
        |> put_flash(:success, "Character created successfully.")
        |> redirect(to: ~p"/characters/#{character}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    character = Characters.get_character(id)
    render(conn, :show, character: character)
  end

  def edit(conn, %{"id" => id}) do
    character = Characters.get_character(id)
    changeset = Ecto.Changeset.change(character)
    render(conn, :edit, character: character, changeset: changeset)
  end

  def update(conn, %{"id" => id, "character" => character_params}) do
    # TODO This should be removed once we have the skills relationship, issue: https://github.com/lambdaclass/mirra_backend/issues/717
    skills = Jason.decode!(character_params["skills"])
    character_params = Map.put(character_params, "skills", skills)
    character = Characters.get_character(id)

    case Characters.update_character(character, character_params) do
      {:ok, character} ->
        conn
        |> put_flash(:success, "Character updated successfully.")
        |> redirect(to: ~p"/characters/#{character}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, character: character, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    character = Characters.get_character(id)
    {:ok, _character} = Characters.delete_character(character)

    conn
    |> put_flash(:success, "Character deleted successfully.")
    |> redirect(to: ~p"/characters")
  end
end
