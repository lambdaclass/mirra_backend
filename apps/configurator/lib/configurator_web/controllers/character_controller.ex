defmodule ConfiguratorWeb.CharacterController do
  use ConfiguratorWeb, :controller

  alias Configurator.Configuration
  alias Configurator.Configuration.Character
  alias ConfiguratorWeb.Utils

  def index(conn, _params) do
    characters = Configuration.list_characters()
    render(conn, :index, characters: characters)
  end

  def new(conn, _params) do
    changeset = Configuration.change_character(%Character{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"character" => character_params}) do
    # TODO This should be removed once we have the skills relationship, issue: https://github.com/lambdaclass/mirra_backend/issues/717
    skills = Jason.decode!(character_params["skills"])
    character_params = Map.put(character_params, "skills", skills)

    case Configuration.create_character(character_params) do
      {:ok, character} ->
        conn
        |> put_flash(:info, "Character created successfully.")
        |> redirect(to: ~p"/characters/#{character}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    character = Configuration.get_character!(id)
    render(conn, :show, character: character)
  end

  def edit(conn, %{"id" => id}) do
    character = Configuration.get_character!(id)
    changeset = Configuration.change_character(character)
    render(conn, :edit, character: character, changeset: changeset)
  end

  def update(conn, %{"id" => id, "character" => character_params}) do
    # TODO This should be removed once we have the skills relationship, issue: https://github.com/lambdaclass/mirra_backend/issues/717
    skills = Jason.decode!(character_params["skills"])
    character_params = Map.put(character_params, "skills", skills)
    character = Configuration.get_character!(id)

    case Configuration.update_character(character, character_params) do
      {:ok, character} ->
        conn
        |> put_flash(:info, "Character updated successfully.")
        |> redirect(to: ~p"/characters/#{character}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, character: character, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    character = Configuration.get_character!(id)
    {:ok, _character} = Configuration.delete_character(character)

    conn
    |> put_flash(:info, "Character deleted successfully.")
    |> redirect(to: ~p"/characters")
  end

  def characters(conn, _params) do
    characters = Utils.list_characters()

    send_resp(conn, 200, Jason.encode!(characters))
  end
end
