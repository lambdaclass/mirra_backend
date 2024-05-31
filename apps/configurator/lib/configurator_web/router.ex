defmodule ConfiguratorWeb.Router do
  use ConfiguratorWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ConfiguratorWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ConfiguratorWeb do
    pipe_through :browser

    resources "/games", GameController, only: [:index, :new, :create, :show] do
      resources "/configuration_groups", ConfigurationGroupController, only: [:new, :create, :show] do
        resources "/configurations", ConfigurationController, only: [:new, :create, :show]
        put "/configurations/set_default/:id", ConfigurationController, :set_default
      end
    end
  end

  scope "/api", ConfiguratorWeb do
    pipe_through :api

    get "/default_config", ConfigurationController, :show
    get "/configurations/:id", ConfigurationController, :show
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
end
