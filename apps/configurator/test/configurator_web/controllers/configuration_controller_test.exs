defmodule ConfiguratorWeb.ConfigurationControllerTest do
  use ConfiguratorWeb.ConnCase

  import Configurator.ConfigureFixtures

  @create_attrs %{data: "{}", is_default: false}
  @invalid_attrs %{data: "not_json", is_default: nil}

  setup do
    configuration_fixture()
    :ok
  end

  describe "index" do
    test "lists all configurations", %{conn: conn} do
      conn = get(conn, ~p"/configurations")
      assert html_response(conn, 200) =~ "Listing Configurations"
    end
  end

  describe "new configuration" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/configurations/new")
      assert html_response(conn, 200) =~ "New Configuration"
    end
  end

  describe "create configuration" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/configurations", configuration: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/configurations/#{id}"

      conn = get(conn, ~p"/configurations/#{id}")
      assert html_response(conn, 200) =~ "Configuration #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/configurations", configuration: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Configuration"
    end
  end
end
