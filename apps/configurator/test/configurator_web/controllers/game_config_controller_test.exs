defmodule ConfiguratorWeb.GameConfigControllerTest do
  use ConfiguratorWeb.ConnCase

  import Configurator.ConfigurationFixtures

  @create_attrs %{end_game_interval_ms: 42, item_spawn_interval_ms: 42, natural_healing_interval_ms: 42, shutdown_game_wait_ms: 42, start_game_time_ms: 42, tick_rate_ms: 42, zone_damage_interval_ms: 42, zone_damage: 42, zone_shrink_interval: 42, zone_shrink_radius_by: 42, zone_shrink_start_ms: 42, zone_start_interval_ms: 42, zone_stop_interval_ms: 42}
  @update_attrs %{end_game_interval_ms: 43, item_spawn_interval_ms: 43, natural_healing_interval_ms: 43, shutdown_game_wait_ms: 43, start_game_time_ms: 43, tick_rate_ms: 43, zone_damage_interval_ms: 43, zone_damage: 43, zone_shrink_interval: 43, zone_shrink_radius_by: 43, zone_shrink_start_ms: 43, zone_start_interval_ms: 43, zone_stop_interval_ms: 43}
  @invalid_attrs %{end_game_interval_ms: nil, item_spawn_interval_ms: nil, natural_healing_interval_ms: nil, shutdown_game_wait_ms: nil, start_game_time_ms: nil, tick_rate_ms: nil, zone_damage_interval_ms: nil, zone_damage: nil, zone_shrink_interval: nil, zone_shrink_radius_by: nil, zone_shrink_start_ms: nil, zone_start_interval_ms: nil, zone_stop_interval_ms: nil}

  describe "index" do
    test "lists all game_configurations", %{conn: conn} do
      conn = get(conn, ~p"/game_configurations")
      assert html_response(conn, 200) =~ "Listing Game configurations"
    end
  end

  describe "new game_config" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/game_configurations/new")
      assert html_response(conn, 200) =~ "New Game config"
    end
  end

  describe "create game_config" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/game_configurations", game_config: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/game_configurations/#{id}"

      conn = get(conn, ~p"/game_configurations/#{id}")
      assert html_response(conn, 200) =~ "Game config #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/game_configurations", game_config: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Game config"
    end
  end

  describe "edit game_config" do
    setup [:create_game_config]

    test "renders form for editing chosen game_config", %{conn: conn, game_config: game_config} do
      conn = get(conn, ~p"/game_configurations/#{game_config}/edit")
      assert html_response(conn, 200) =~ "Edit Game config"
    end
  end

  describe "update game_config" do
    setup [:create_game_config]

    test "redirects when data is valid", %{conn: conn, game_config: game_config} do
      conn = put(conn, ~p"/game_configurations/#{game_config}", game_config: @update_attrs)
      assert redirected_to(conn) == ~p"/game_configurations/#{game_config}"

      conn = get(conn, ~p"/game_configurations/#{game_config}")
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, game_config: game_config} do
      conn = put(conn, ~p"/game_configurations/#{game_config}", game_config: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Game config"
    end
  end

  describe "delete game_config" do
    setup [:create_game_config]

    test "deletes chosen game_config", %{conn: conn, game_config: game_config} do
      conn = delete(conn, ~p"/game_configurations/#{game_config}")
      assert redirected_to(conn) == ~p"/game_configurations"

      assert_error_sent 404, fn ->
        get(conn, ~p"/game_configurations/#{game_config}")
      end
    end
  end

  defp create_game_config(_) do
    game_config = game_config_fixture()
    %{game_config: game_config}
  end
end
