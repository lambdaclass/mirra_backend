defmodule DarkWorldsServerWeb.Router do
  use DarkWorldsServerWeb, :router
  import DarkWorldsServerWeb.UserAuth

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {DarkWorldsServerWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)
  end

  pipeline :game do
    plug(:put_root_layout, {DarkWorldsServerWeb.Layouts, :game})
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", DarkWorldsServerWeb do
    pipe_through(:api)

    post "/bot", BotController, :create
    post "/config/clean_import", ConfigController, :clean_import
  end

  scope "/", DarkWorldsServerWeb do
    pipe_through(:browser)

    get "/", PageController, :home
    get "/current_lobbies", LobbyController, :current_lobbies
    get "/join_lobby", LobbyController, :join
    get "/current_games", GameController, :current_games
    get "/player_game/:player_id", GameController, :player_game
  end

  scope "/users-characters", DarkWorldsServerWeb do
    get "/:device_client_id", CharacterController, :get_player
    post "/new", CharacterController, :create_player
    put "/:device_client_id/edit", CharacterController, :update_player
  end

  scope "/", DarkWorldsServerWeb do
    pipe_through([:browser, :game])

    live("/board/:game_id/:player_id", BoardLive.Show)

    live_session :authenticated, on_mount: [{DarkWorldsServerWeb.UserAuth, :ensure_authenticated}] do
      live("/matchmaking", MatchmakingLive.Index)
      live("/matchmaking/:session_id/:player_name", MatchmakingLive.Show)
    end
  end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:dark_worlds_server, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard",
        metrics: DarkWorldsServerWeb.Telemetry,
        additional_pages:
          [] ++
            if System.get_env("FLAMEGRAPH") do
              [flame_on: FlameOn.DashboardPage]
            else
              []
            end
      )

      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end

  ###########################
  ## Authentication routes ##
  ###########################
  scope "/", DarkWorldsServerWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{DarkWorldsServerWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live("/users/register", UserRegistrationLive, :new)
      live("/users/log_in", UserLoginLive, :new)
      live("/users/reset_password", UserForgotPasswordLive, :new)
      live("/users/reset_password/:token", UserResetPasswordLive, :edit)
    end

    post("/users/log_in", UserSessionController, :create)
  end

  scope "/", DarkWorldsServerWeb do
    pipe_through([:browser, :require_authenticated_user])

    live_session :require_authenticated_user,
      on_mount: [{DarkWorldsServerWeb.UserAuth, :ensure_authenticated}] do
      live("/users/settings", UserSettingsLive, :edit)
      live("/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email)
    end
  end

  scope "/", DarkWorldsServerWeb do
    pipe_through([:browser])

    delete("/users/log_out", UserSessionController, :delete)

    live_session :current_user,
      on_mount: [{DarkWorldsServerWeb.UserAuth, :mount_current_user}] do
      live("/users/confirm/:token", UserConfirmationLive, :edit)
      live("/users/confirm", UserConfirmationInstructionsLive, :new)
    end
  end
end
