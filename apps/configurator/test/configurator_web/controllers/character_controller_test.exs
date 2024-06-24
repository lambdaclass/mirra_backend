defmodule ConfiguratorWeb.CharacterControllerTest do
  use ConfiguratorWeb.ConnCase

  import Configurator.ConfigurationFixtures

  @create_attrs %{
    active: true,
    base_health: 42,
    base_size: 120.5,
    base_speed: 120.5,
    base_stamina: 42,
    name: "some name",
    max_inventory_size: 42,
    natural_healing_damage_interval: 42,
    natural_healing_interval: 42,
    stamina_interval: 42,
    skills: "{}"
  }
  @update_attrs %{
    active: true,
    base_health: 42,
    base_size: 120.5,
    base_speed: 120.5,
    base_stamina: 42,
    name: "some updated name",
    max_inventory_size: 42,
    natural_healing_damage_interval: 42,
    natural_healing_interval: 42,
    stamina_interval: 42,
    skills: "{}"
  }

  @invalid_attrs %{
    active: nil,
    name: nil,
    base_speed: nil,
    base_size: nil,
    base_health: nil,
    base_stamina: nil,
    skills: "{}"
  }

  describe "index" do
    test "lists all characters", %{conn: conn} do
      conn = get(conn, ~p"/characters")
      assert html_response(conn, 200) =~ "Listing Characters"
    end
  end

  describe "new character" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/characters/new")
      assert html_response(conn, 200) =~ "New Character"
    end
  end

  describe "create character" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/characters", character: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/characters/#{id}"

      conn = get(conn, ~p"/characters/#{id}")
      assert html_response(conn, 200) =~ "Character #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/characters", character: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Character"
    end
  end

  describe "edit character" do
    setup [:create_character]

    test "renders form for editing chosen character", %{conn: conn, character: character} do
      conn = get(conn, ~p"/characters/#{character}/edit")
      assert html_response(conn, 200) =~ "Edit Character"
    end
  end

  describe "update character" do
    setup [:create_character]

    test "redirects when data is valid", %{conn: conn, character: character} do
      conn = put(conn, ~p"/characters/#{character}", character: @update_attrs)
      assert redirected_to(conn) == ~p"/characters/#{character}"

      conn = get(conn, ~p"/characters/#{character}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, character: character} do
      conn = put(conn, ~p"/characters/#{character}", character: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Character"
    end
  end

  describe "delete character" do
    setup [:create_character]

    test "deletes chosen character", %{conn: conn, character: character} do
      conn = delete(conn, ~p"/characters/#{character}")
      assert redirected_to(conn) == ~p"/characters"

      assert_error_sent 404, fn ->
        get(conn, ~p"/characters/#{character}")
      end
    end
  end

  defp create_character(_) do
    character = character_fixture()
    %{character: character}
  end
end
