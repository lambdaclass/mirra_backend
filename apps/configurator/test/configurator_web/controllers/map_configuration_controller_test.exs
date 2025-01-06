defmodule ConfiguratorWeb.MapConfigurationControllerTest do
  use ConfiguratorWeb.ConnCase

  import Configurator.ConfigurationFixtures
  import Configurator.AccountsFixtures
  setup [:create_authenticated_conn, :create_version]

  @create_attrs %{
    name: "some_map",
    radius: "120.5",
    initial_positions: "",
    obstacles: "",
    bushes: "",
    pools: "",
    crates: "",
    active: true,
    square_wall: ""
  }
  @update_attrs %{
    name: "another_map",
    radius: "456.7",
    initial_positions: "",
    obstacles: "",
    bushes: "",
    pools: "",
    crates: "",
    active: false,
    square_wall: nil
  }
  @invalid_attrs %{
    name: nil,
    radius: nil,
    initial_positions: nil,
    obstacles: nil,
    bushes: nil,
    pools: nil,
    crates: nil,
    active: nil,
    square_wall: ""
  }

  describe "index" do
    test "lists all map_configurations", %{conn: conn, version: version} do
      conn = get(conn, ~p"/versions/#{version.id}/map_configurations")
      assert html_response(conn, 200) =~ "Listing Map configurations"
    end
  end

  describe "new map_configuration" do
    test "renders form", %{conn: conn, version: version} do
      conn = get(conn, ~p"/versions/#{version.id}/map_configurations/new")
      assert html_response(conn, 200) =~ "New Map configuration"
    end
  end

  describe "create map_configuration" do
    test "redirects to show when data is valid", %{conn: conn, version: version} do
      conn =
        post(conn, ~p"/versions/#{version.id}/map_configurations",
          map_configuration: @create_attrs |> Map.put(:version_id, version.id)
        )

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/versions/#{version.id}/map_configurations/#{id}"

      conn = get(conn, ~p"/versions/#{version.id}/map_configurations/#{id}")
      assert html_response(conn, 200) =~ "Map configuration #{@create_attrs.name}"
    end

    test "renders errors when data is invalid", %{conn: conn, version: version} do
      conn =
        post(conn, ~p"/versions/#{version.id}/map_configurations",
          map_configuration: @invalid_attrs |> Map.put(:version_id, version.id)
        )

      assert html_response(conn, 200) =~ "New Map configuration"
    end
  end

  describe "edit map_configuration" do
    setup [:create_map_configuration]

    test "renders form for editing chosen map_configuration", %{conn: conn, map_configuration: map_configuration} do
      conn = get(conn, ~p"/versions/#{map_configuration.version_id}/map_configurations/#{map_configuration}/edit")
      assert html_response(conn, 200) =~ "Edit Map configuration"
    end
  end

  describe "update map_configuration" do
    setup [:create_map_configuration]

    test "redirects when data is valid", %{conn: conn, map_configuration: map_configuration} do
      conn =
        put(conn, ~p"/versions/#{map_configuration.version_id}/map_configurations/#{map_configuration}",
          map_configuration: @update_attrs
        )

      assert redirected_to(conn) ==
               ~p"/versions/#{map_configuration.version_id}/map_configurations/#{map_configuration}"

      conn = get(conn, ~p"/versions/#{map_configuration.version_id}/map_configurations/#{map_configuration}")
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, map_configuration: map_configuration} do
      conn =
        put(conn, ~p"/versions/#{map_configuration.version_id}/map_configurations/#{map_configuration}",
          map_configuration: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit Map configuration"
    end
  end

  describe "delete map_configuration" do
    setup [:create_map_configuration]

    test "deletes chosen map_configuration", %{conn: conn, map_configuration: map_configuration} do
      map_configuration_version_id = map_configuration.version_id
      conn = delete(conn, ~p"/versions/#{map_configuration_version_id}/map_configurations/#{map_configuration}")
      assert redirected_to(conn) == ~p"/versions/#{map_configuration_version_id}/map_configurations"

      assert_error_sent 404, fn ->
        get(conn, ~p"/versions/#{map_configuration_version_id}/map_configurations/#{map_configuration}")
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
      |> Plug.Conn.put_session(:current_user, user)

    %{conn: conn}
  end

  defp create_version(_) do
    %{version: version_fixture()}
  end
end
