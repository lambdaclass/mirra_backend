defmodule ConfiguratorWeb.VersionControllerTest do
  use ConfiguratorWeb.ConnCase

  import Configurator.ConfigurationFixtures
  import Configurator.AccountsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup [:create_authenticated_conn]

  describe "index" do
    test "lists all versions", %{conn: conn} do
      conn = get(conn, ~p"/versions")
      assert html_response(conn, 200) =~ "Listing Versions"
    end
  end

  describe "new version" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/versions/new")
      assert html_response(conn, 200) =~ "New Version"
    end
  end

  describe "create version" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/versions", version: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/versions/#{id}"

      conn = get(conn, ~p"/versions/#{id}")
      assert html_response(conn, 200) =~ "Version #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/versions", version: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Version"
    end
  end

  describe "edit version" do
    setup [:create_version]

    test "renders form for editing chosen version", %{conn: conn, version: version} do
      conn = get(conn, ~p"/versions/#{version}/edit")
      assert html_response(conn, 200) =~ "Edit Version"
    end
  end

  describe "update version" do
    setup [:create_version]

    test "redirects when data is valid", %{conn: conn, version: version} do
      conn = put(conn, ~p"/versions/#{version}", version: @update_attrs)
      assert redirected_to(conn) == ~p"/versions/#{version}"

      conn = get(conn, ~p"/versions/#{version}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, version: version} do
      conn = put(conn, ~p"/versions/#{version}", version: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Version"
    end
  end

  describe "delete version" do
    setup [:create_version]

    test "deletes chosen version", %{conn: conn, version: version} do
      conn = delete(conn, ~p"/versions/#{version}")
      assert redirected_to(conn) == ~p"/versions"

      assert_error_sent 404, fn ->
        get(conn, ~p"/versions/#{version}")
      end
    end
  end

  defp create_version(_) do
    version = version_fixture()
    %{version: version}
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
