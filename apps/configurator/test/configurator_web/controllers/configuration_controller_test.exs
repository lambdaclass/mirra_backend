defmodule ConfiguratorWeb.ConfigurationControllerTest do
  use ConfiguratorWeb.ConnCase

  import Configurator.ConfigureFixtures
  import Configurator.GameFixtures

  @create_attrs %{name: "some_name", data: "{}", current: false}
  @invalid_attrs %{name: nil, data: "not_json", current: nil}

  setup do
    game = game_fixture()
    configuration_group = configuration_group_fixture(%{game_id: game.id})
    {:ok, configuration_group: configuration_group, game: game}
  end

  describe "new configuration" do
    test "renders form", %{conn: conn, game: game, configuration_group: configuration_group} do
      conn = get(conn, ~p"/games/#{game}/configuration_groups/#{configuration_group}/configurations/new")
      assert html_response(conn, 200) =~ "New configuration for #{configuration_group.name} in #{game.name}"
    end
  end

  describe "create configuration" do
    test "redirects to show when data is valid", %{conn: conn, game: game, configuration_group: configuration_group} do
      game = game_fixture()
      configuration_group = configuration_group_fixture(%{game_id: game.id})
      params = Map.put(@create_attrs, :configuration_group_id, configuration_group.id)

      conn =
        post(conn, ~p"/games/#{game}/configuration_groups/#{configuration_group}/configurations/",
          configuration: params
        )

      assert redirected_to(conn) == ~p"/games/#{game}/configuration_groups/#{configuration_group}"

      conn = get(conn, ~p"/games/#{game}/configuration_groups/#{configuration_group}")
      assert html_response(conn, 200) =~ "#{configuration_group.name}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      game = game_fixture()
      configuration_group = configuration_group_fixture(%{game_id: game.id})
      params = Map.put(@invalid_attrs, :configuration_group_id, configuration_group.id)

      conn =
        post(conn, ~p"/games/#{game}/configuration_groups/#{configuration_group}/configurations/",
          configuration: params
        )

      assert html_response(conn, 200) =~ "New configuration"
    end
  end
end
