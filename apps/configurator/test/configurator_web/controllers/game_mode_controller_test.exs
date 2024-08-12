defmodule ConfiguratorWeb.GameModeControllerTest do
  use ConfiguratorWeb.ConnCase

  import Configurator.ConfigurationFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  describe "index" do
    test "lists all game_modes", %{conn: conn} do
      conn = get(conn, ~p"/game_modes")
      assert html_response(conn, 200) =~ "Listing Game modes"
    end
  end

  describe "new game_mode" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/game_modes/new")
      assert html_response(conn, 200) =~ "New Game mode"
    end
  end

  describe "create game_mode" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/game_modes", game_mode: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/game_modes/#{id}"

      conn = get(conn, ~p"/game_modes/#{id}")
      assert html_response(conn, 200) =~ "Game mode #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/game_modes", game_mode: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Game mode"
    end
  end

  describe "edit game_mode" do
    setup [:create_game_mode]

    test "renders form for editing chosen game_mode", %{conn: conn, game_mode: game_mode} do
      conn = get(conn, ~p"/game_modes/#{game_mode}/edit")
      assert html_response(conn, 200) =~ "Edit Game mode"
    end
  end

  describe "update game_mode" do
    setup [:create_game_mode]

    test "redirects when data is valid", %{conn: conn, game_mode: game_mode} do
      conn = put(conn, ~p"/game_modes/#{game_mode}", game_mode: @update_attrs)
      assert redirected_to(conn) == ~p"/game_modes/#{game_mode}"

      conn = get(conn, ~p"/game_modes/#{game_mode}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, game_mode: game_mode} do
      conn = put(conn, ~p"/game_modes/#{game_mode}", game_mode: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Game mode"
    end
  end

  describe "delete game_mode" do
    setup [:create_game_mode]

    test "deletes chosen game_mode", %{conn: conn, game_mode: game_mode} do
      conn = delete(conn, ~p"/game_modes/#{game_mode}")
      assert redirected_to(conn) == ~p"/game_modes"

      assert_error_sent 404, fn ->
        get(conn, ~p"/game_modes/#{game_mode}")
      end
    end
  end

  defp create_game_mode(_) do
    game_mode = game_mode_fixture()
    %{game_mode: game_mode}
  end
end
