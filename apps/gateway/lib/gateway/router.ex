defmodule Gateway.Router do
  use Gateway, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/champions", Gateway.Champions do
    pipe_through :api
  end

  scope "/curse", Gateway.Controllers.CurseOfMirra do
    pipe_through :api

    post "/match/:match_id", MatchResultsController, :create
    get "/get_bounties", QuestController, :get_bounties

    scope "/characters" do
      get "/configuration", CharacterController, :get_characters_config
    end

    scope "/stores" do
      get "/:store_name/list_items", StoreController, :list_items
    end

    post "/users", UserController, :create_guest_user

    resources "/users", UserController, only: [:show]

    scope "/users/:user_id/" do
      put "/currency", CurrencyController, :modify_currency
      get "/claim_daily_reward", UserController, :claim_daily_reward
      get "/get_daily_reward_status", UserController, :get_daily_reward_status
      get "/quest/:quest_id/reroll_daily_quest", QuestController, :reroll_daily_quest
      get "/quest/:quest_id/complete_bounty", QuestController, :complete_bounty

      scope "/items" do
        put "/equip", ItemController, :equip
      end

      scope "/stores" do
        put "/:store_name/buy_item", StoreController, :buy_item
      end
    end
  end

  scope "/", Gateway do
    pipe_through :api

    get "/api/health", Controllers.HealthController, :check

    get "/auth/:provider/token/:token_id/:client_id", Controllers.AuthController, :validate_token
    get "/auth/public-key", Controllers.AuthController, :public_key
    post "/auth/refresh-token", Controllers.AuthController, :refresh_token

    put "/users/:user_id", Controllers.UserController, :update
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
