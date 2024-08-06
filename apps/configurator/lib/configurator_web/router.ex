defmodule ConfiguratorWeb.Router do
  use ConfiguratorWeb, :router

  import ConfiguratorWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ConfiguratorWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Other scopes may use custom stacks.
  # scope "/api", ConfiguratorWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:configurator, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ConfiguratorWeb.Telemetry
    end
  end

  ## Authentication routes

  scope "/", ConfiguratorWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{ConfiguratorWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/log_in", UserLoginLive, :new
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", ConfiguratorWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/", HomeController, :home
    resources "/characters", CharacterController
    resources "/skills", SkillController
    resources "/game_configurations", GameConfigurationController
    resources "/map_configurations", MapConfigurationController
    get "/map_configurations/:id/edit_obstacles", MapConfigurationController, :edit_obstacles
    put "/map_configurations/:id/update_obstacles", MapConfigurationController, :update_obstacles
    get "/map_configurations/:id/edit_pools", MapConfigurationController, :edit_pools
    put "/map_configurations/:id/update_pools", MapConfigurationController, :update_pools
    resources "/consumable_items", ConsumableItemController

    scope "/versions" do
      resources "/", VersionController
      put "/:id/current", VersionController, :mark_as_current
    end
  end

  scope "/", ConfiguratorWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
  end
end
