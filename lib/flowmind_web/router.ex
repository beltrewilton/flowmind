defmodule FlowmindWeb.Router do
  use FlowmindWeb, :router

  import FlowmindWeb.UserAuth

  pipeline :browser do
    plug Corsica, origins: "*", allow_credentials: true, allow_methods: :all, allow_headers: :all
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FlowmindWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", FlowmindWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", FlowmindWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:flowmind, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: FlowmindWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", FlowmindWeb do
    pipe_through [:browser]

    live_session :default do
      live "/google_helper", GoogleLiveHelper, :index
    end

    get "/google_auth_url", GoogleAuthController, :redirect_to
  end

  ## Authentication routes

  scope "/", FlowmindWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{FlowmindWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", FlowmindWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      layout: {FlowmindWeb.DashboardLayouts, :app},
      on_mount: [
        {FlowmindWeb.UserAuth, :ensure_authenticated},
        {FlowmindWeb.AttachHookUtil, :attach_hook_util},
        {FlowmindWeb.UserAuth, :load_chat_inbox}
      ] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      live "/demo", DemoLive, :index
      live "/dashboard", HomeLive, :index
      live "/another", AnotherLive, :index
      live "/not_authorized", NotAuthorized, :index
    end

    live_session :by_pass_live,
      layout: {FlowmindWeb.DashboardLayouts, :app},
      on_mount: [
        {FlowmindWeb.UserAuth, :ensure_authenticated},
        {FlowmindWeb.UserAuth, :ensure_admin_or_user},
        {FlowmindWeb.AttachHookUtil, :attach_hook_util}
      ] do
      live "/userlist", UserListLive, :index
      live "/userprofile/:id", UserProfileLive, :index
      live "/usernew", UserNewLive, :index
    end

    live_session :by_pass_live_1,
      layout: {FlowmindWeb.DashboardLayouts, :app},
      on_mount: [
        {FlowmindWeb.UserAuth, :ensure_authenticated},
        {FlowmindWeb.AttachHookUtil, :attach_hook_util},
        {FlowmindWeb.UserAuth, :load_chat_inbox},
        {FlowmindWeb.UserAuth, :ensure_has_phone_number_id}
      ] do
      live "/chat/:phone_number_id", ChatLiveLanding, :index
    end

    live_session :by_pass_live_2,
      layout: {FlowmindWeb.DashboardLayouts, :app},
      on_mount: [
        {FlowmindWeb.UserAuth, :ensure_authenticated},
        {FlowmindWeb.AttachHookUtil, :attach_hook_util},
        {FlowmindWeb.UserAuth, :load_chat_inbox},
        {FlowmindWeb.UserAuth, :ensure_has_customer}
      ] do
      live "/chat/:phone_number_id/:sender_phone_number", ChatLive, :index
    end
  end

  scope "/", FlowmindWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{FlowmindWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
