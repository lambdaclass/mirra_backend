defmodule ConfiguratorWeb.MapConfigurationControllerTest do
  use ConfiguratorWeb.ConnCase

  import GameBackend.ConfigurationFixtures

  @create_attrs %{radius: "120.5", initial_positions: %{}, obstacles: %{}, bushes: %{}}
  @update_attrs %{radius: "456.7", initial_positions: %{}, obstacles: %{}, bushes: %{}}
  @invalid_attrs %{radius: nil, initial_positions: nil, obstacles: nil, bushes: nil}

  describe "index" do
    test "lists all map_configurations", %{conn: conn} do
      conn = get(conn, ~p"/map_configurations")
      assert html_response(conn, 200) =~ "Listing Map configurations"
    end
  end

  describe "new map_configuration" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/map_configurations/new")
      assert html_response(conn, 200) =~ "New Map configuration"
    end
  end

  describe "create map_configuration" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/map_configurations", map_configuration: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/map_configurations/#{id}"

      conn = get(conn, ~p"/map_configurations/#{id}")
      assert html_response(conn, 200) =~ "Map configuration #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/map_configurations", map_configuration: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Map configuration"
    end
  end

  describe "edit map_configuration" do
    setup [:create_map_configuration]

    test "renders form for editing chosen map_configuration", %{conn: conn, map_configuration: map_configuration} do
      conn = get(conn, ~p"/map_configurations/#{map_configuration}/edit")
      assert html_response(conn, 200) =~ "Edit Map configuration"
    end
  end

  describe "update map_configuration" do
    setup [:create_map_configuration]

    test "redirects when data is valid", %{conn: conn, map_configuration: map_configuration} do
      conn = put(conn, ~p"/map_configurations/#{map_configuration}", map_configuration: @update_attrs)
      assert redirected_to(conn) == ~p"/map_configurations/#{map_configuration}"

      conn = get(conn, ~p"/map_configurations/#{map_configuration}")
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, map_configuration: map_configuration} do
      conn = put(conn, ~p"/map_configurations/#{map_configuration}", map_configuration: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Map configuration"
    end
  end

  describe "delete map_configuration" do
    setup [:create_map_configuration]

    test "deletes chosen map_configuration", %{conn: conn, map_configuration: map_configuration} do
      conn = delete(conn, ~p"/map_configurations/#{map_configuration}")
      assert redirected_to(conn) == ~p"/map_configurations"

      assert_error_sent 404, fn ->
        get(conn, ~p"/map_configurations/#{map_configuration}")
      end
    end
  end

  defp create_map_configuration(_) do
    map_configuration = map_configuration_fixture()
    %{map_configuration: map_configuration}
  end
end
