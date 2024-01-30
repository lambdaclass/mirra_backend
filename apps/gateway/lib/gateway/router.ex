defmodule Gateway.Router do
  use Gateway, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/champions", Gateway.Champions do
    pipe_through :api
    get "/users/:user_id", UsersController, :get_user
    get "/users/:username/id", UsersController, :get_id
    post "/users/:username", UsersController, :create_user

    scope "/users/:user_id" do
      get "/campaigns", CampaignsController, :get_campaigns
      get "/campaigns/:campaign_number", CampaignsController, :get_campaign
      get "/levels/:level_id", CampaignsController, :get_level
      post "/levels/:level_id/battle", CampaignsController, :fight_level
      post "/units/:unit_id/select/:slot", UnitsController, :select
      post "/units/:unit_id/unselect", UnitsController, :unselect
      post "/items/:item_id/equip_to/:unit_id", ItemsController, :equip_item
      post "/items/:item_id/unequip/", ItemsController, :unequip_item
      get "/items/:item_id", ItemsController, :get_item
      post "/items/:item_id/level_up", ItemsController, :level_up
    end
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
