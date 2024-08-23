defmodule ConfiguratorWeb.ArenaServerControllerTest do
  use ConfiguratorWeb.ConnCase

  import Configurator.ConfigurationFixtures
  import Configurator.AccountsFixtures
  use Plug.Test

  setup [:create_authenticated_conn]

  @create_attrs %{name: "some name", ip: "some ip", url: "some url", gateway_url: "some gateway url", status: :active, environment: :production}
  @update_attrs %{
    name: "some updated name",
    ip: "some updated ip",
    url: "some updated url",
    gateway_url: "some updated GATEWAY url",
    status: :inactive,
    environment: :development
  }
  @invalid_attrs %{name: nil, ip: nil, url: nil, status: nil}

  describe "index" do
    test "lists all arena_servers", %{conn: conn} do
      conn = get(conn, ~p"/arena_servers")
      assert html_response(conn, 200) =~ "Listing Arena servers"
    end
  end

  describe "new arena_server" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/arena_servers/new")
      assert html_response(conn, 200) =~ "New Arena server"
    end
  end

  describe "create arena_server" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/arena_servers", arena_server: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/arena_servers/#{id}"

      conn = get(conn, ~p"/arena_servers/#{id}")
      assert html_response(conn, 200) =~ "Arena server #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/arena_servers", arena_server: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Arena server"
    end
  end

  describe "edit arena_server" do
    setup [:create_arena_server]

    test "renders form for editing chosen arena_server", %{conn: conn, arena_server: arena_server} do
      conn = get(conn, ~p"/arena_servers/#{arena_server}/edit")
      assert html_response(conn, 200) =~ "Edit Arena server"
    end
  end

  describe "update arena_server" do
    setup [:create_arena_server]

    test "redirects when data is valid", %{conn: conn, arena_server: arena_server} do
      conn = put(conn, ~p"/arena_servers/#{arena_server}", arena_server: @update_attrs)
      assert redirected_to(conn) == ~p"/arena_servers/#{arena_server}"

      conn = get(conn, ~p"/arena_servers/#{arena_server}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, arena_server: arena_server} do
      conn = put(conn, ~p"/arena_servers/#{arena_server}", arena_server: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Arena server"
    end
  end

  describe "delete arena_server" do
    setup [:create_arena_server]

    test "deletes chosen arena_server", %{conn: conn, arena_server: arena_server} do
      conn = delete(conn, ~p"/arena_servers/#{arena_server}")
      assert redirected_to(conn) == ~p"/arena_servers"

      assert_error_sent 404, fn ->
        get(conn, ~p"/arena_servers/#{arena_server}")
      end
    end
  end

  defp create_arena_server(_) do
    arena_server = arena_server_fixture()
    %{arena_server: arena_server}
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
end
