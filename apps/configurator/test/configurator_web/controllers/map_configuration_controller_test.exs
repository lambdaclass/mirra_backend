defmodule ConfiguratorWeb.MapConfigurationControllerTest do
  use ConfiguratorWeb.ConnCase

  import Configurator.ConfigurationFixtures
  import Configurator.AccountsFixtures
  setup [:create_authenticated_conn]

  @create_attrs %{name: "some_map", radius: "120.5", initial_positions: "", obstacles: "", bushes: "", pools: ""}
  @update_attrs %{name: "another_map", radius: "456.7", initial_positions: "", obstacles: "", bushes: "", pools: ""}
  @invalid_attrs %{name: nil, radius: nil, initial_positions: nil, obstacles: nil, bushes: nil, pools: nil}

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
      version = version_fixture()
      conn = post(conn, ~p"/map_configurations", map_configuration: @create_attrs |> Map.put(:version_id, version.id))

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/map_configurations/#{id}"

      conn = get(conn, ~p"/map_configurations/#{id}")
      assert html_response(conn, 200) =~ "Map configuration #{@create_attrs.name}"
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

  defp create_authenticated_conn(%{conn: conn}) do
    user = user_fixture()
    token = Configurator.Accounts.generate_user_session_token(user)

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{})
      |> Plug.Conn.put_session(:user_token, token)

    %{conn: conn}
  end
end
