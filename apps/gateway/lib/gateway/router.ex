defmodule Gateway.Router do
  use Gateway, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GameClientWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/champions", Gateway.Champions do
    pipe_through :api
  end

  scope "/auth", Gateway do
    pipe_through :browser

    get "/browser/:provider", Controllers.AuthController, :request
    get "/browser/:provider/callback", Controllers.AuthController, :callback
    get "/unity/:provider", Controllers.AuthController, :request
    get "/unity/:provider/callback", Controllers.AuthController, :callback
  end

  scope "/users", Gateway do
    pipe_through :api

    get "/:user_id", Controllers.UserController, :get_email
  end

  # Other scopes may use custom stacks.
  # scope "/api", Gateway do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:gateway, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: Gateway.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
