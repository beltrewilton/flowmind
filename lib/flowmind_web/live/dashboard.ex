defmodule FlowmindWeb.DashboardLive do
  alias Flowmind.Accounts
  use FlowmindWeb, :live_view

  def doc do
    "Dashboard"
  end

  @impl true
  def mount(_params, _session, socket) do
    tenant = Flowmind.TenantGenServer.get_tenant()

    tenant_accounts = Accounts.list_tenant_accounts()

    IO.inspect(tenant_accounts, label: "tenant_accounts")

    socket =
      socket
      |> assign(:tenant, tenant)
      |> assign(:tenant_account, nil)
      |> assign(:tenant_accounts, tenant_accounts)
      |> assign(:access_token, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("fb_login_success", %{"response" => response}, socket) do
    IO.inspect(response, label: "Facebook Login Response")
    token_exchange_code = response["authResponse"]["code"]
    # TODO: Run in Task delay 5 segs ...
    Process.send_after(self(), :run_code_exchange, 5_000)

    socket =
      socket
      |> assign(:fb_response, response)
      |> assign(:token_exchange_code, token_exchange_code)

    {:noreply, socket}
  end

  @impl true
  def handle_event("whatsapp_signup_success", %{"data" => data}, socket) do
    IO.inspect(data, label: "WhatsApp Signup Data")
    {:ok, tenant_account} = Accounts.create_tenant_account(data)

    socket =
      socket
      |> assign(:whatsapp_data, data)
      |> assign(:tenant_account, tenant_account)

    {:noreply, socket}
  end

  def handle_event("dummy_event", data, socket) do
    IO.inspect(data, label: "Dummy Data")
    {:noreply, socket}
  end

  @impl true
  def handle_info(:run_code_exchange, socket) do
    IO.inspect("run_code_exchange")

    tenant_account = socket.assigns[:tenant_account]
    token_exchange_code = socket.assigns[:token_exchange_code]

    {_, oauth_response} = WhatsappElixir.Messages.oauth_access_token(token_exchange_code)
    access_token = oauth_response["access_token"]

    {:ok, tenant_account} =
      Accounts.update_tenant_account(tenant_account, %{
        "token_exchange_code" => token_exchange_code,
        "access_token" => access_token
      })

    # TODO: subscribe_apps
    {_, subscribed_apps_response} =
      WhatsappElixir.Messages.subscribed_apps(access_token, tenant_account.waba_id)

    # TODO: register_phone_number
    {_, register_ph_response} =
      WhatsappElixir.Messages.register_cust_ph(access_token, tenant_account.phone_number_id)
      
    {_, ph} = WhatsappElixir.Messages.fetch_phone_numbers(access_token, tenant_account.waba_id)
  
    phone_number = ph["data"] |> Enum.find(fn d -> d["id"] == tenant_account.phone_number_id end)
    
    {:ok, tenant_account} =
      Accounts.update_tenant_account(tenant_account, %{
        "subscribed_apps_response" => subscribed_apps_response,
        "register_ph_response" => register_ph_response,
        "connected" => subscribed_apps_response["success"] and register_ph_response["success"],
        "display_phone_number" => phone_number["phone_number"],
        "platform_type" => phone_number["platform_type"],
        "quality_rating" => phone_number["quality_rating"],
        "status" => phone_number["status"],
        "verified_name" => phone_number["verified_name"]
      })

    socket =
      socket
      |> assign(:tenant_account, tenant_account)
      |> assign(:access_token, access_token)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.drawer class="lg:drawer-open border w-full min-h-screen" selector_id="drawer">
      <:drawer_content class="pb-10 b-1 bg-base-200">
        <.navbar class="bg-base-100 mb-5 shadow-xl">
          <div class="flex-1">
            <a class="btn btn-ghost text-xl">Flowmind</a>
          </div>
          <div class="flex-none gap-2">
            <.swap animation="rotate">
              <:controller>
                <input type="checkbox" class="theme-controller" value="synthwave" />
              </:controller>
              <:swap_on type="icon" name="hero-sun" />
              <:swap_off type="icon" name="hero-moon" />
            </.swap>
            <div class="flex flex-col">
              <p class="text-xs">{@current_user.name}</p>
              <p class="text-xs">@{@tenant}</p>
            </div>
            <.dropdown align="end">
              <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar">
                <div class="w-10 rounded-full">
                  <img
                    alt="Tailwind CSS Navbar component"
                    src="https://img.daisyui.com/images/stock/photo-1534528741775-53994a69daeb.webp"
                  />
                </div>
              </div>
              <.menu
                tabindex="0"
                size="sm"
                class="dropdown-content bg-base-100 rounded-box z-[1] mt-3 w-52 p-2 shadow"
              >
                <:item>
                  <.link href={~p"/users/settings"}>
                    Settings
                  </.link>
                </:item>
                <:item>
                  <.link href={~p"/users/log_out"} method="delete">
                    Log out
                  </.link>
                </:item>
              </.menu>
            </.dropdown>
          </div>
        </.navbar>

        <%!-- CONTENT HERE --%>
        <div id="fb-root"></div>
        
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-2">
          <%= for tenant_account <- @tenant_accounts do %>
            <.card class="bg-base-200 w-96 h-3/4 ml-10 shadow-xl" padding="compact">
              <figure>
                <img
                  src="/images/4169536.jpg"
                  alt="Shoes"
                />
              </figure>
              <:card_body class="">
                <div class="space-y-2">
                <div class="flex justify-between pb-1 ml-5 mr-5">
                  <span class="font-medium">Account Name</span>
                  <span>{tenant_account.verified_name}</span>
                </div>
                <div class="flex justify-between pb-1 ml-5 mr-5">
                  <span class="font-medium">Phone Number</span>
                  <span>{tenant_account.display_phone_number}</span>
                </div>
                  <div class="flex justify-between pb-1 ml-5 mr-5">
                    <span class="font-medium">Phone Number ID</span>
                    <span>{tenant_account.phone_number_id}</span>
                  </div>
                  <div class="flex justify-between pb-1 ml-5 mr-5">
                    <span class="font-medium">WABA</span>
                    <span>{tenant_account.waba_id}</span>
                  </div>
                  <div class="flex justify-between pb-1 ml-5 mr-5">
                    <span class="font-medium">Quality Rating</span>
                    <span>{tenant_account.quality_rating}</span>
                  </div>
                  <div class="flex justify-between pb-1 ml-5 mr-5">
                    <span class="font-medium">Meta Status</span>
                    <span>{tenant_account.status}</span>
                  </div>
                  <div class="flex justify-between pb-1 ml-5 mr-5">
                    <span class="font-medium">Connected</span>
                    <svg
                      :if={tenant_account.connected}
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 24 24"
                      fill="currentColor"
                      class="size-6 text-green-600"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M8.603 3.799A4.49 4.49 0 0 1 12 2.25c1.357 0 2.573.6 3.397 1.549a4.49 4.49 0 0 1 3.498 1.307 4.491 4.491 0 0 1 1.307 3.497A4.49 4.49 0 0 1 21.75 12a4.49 4.49 0 0 1-1.549 3.397 4.491 4.491 0 0 1-1.307 3.497 4.491 4.491 0 0 1-3.497 1.307A4.49 4.49 0 0 1 12 21.75a4.49 4.49 0 0 1-3.397-1.549 4.49 4.49 0 0 1-3.498-1.306 4.491 4.491 0 0 1-1.307-3.498A4.49 4.49 0 0 1 2.25 12c0-1.357.6-2.573 1.549-3.397a4.49 4.49 0 0 1 1.307-3.497 4.49 4.49 0 0 1 3.497-1.307Zm7.007 6.387a.75.75 0 1 0-1.22-.872l-3.236 4.53L9.53 12.22a.75.75 0 0 0-1.06 1.06l2.25 2.25a.75.75 0 0 0 1.14-.094l3.75-5.25Z"
                        clip-rule="evenodd"
                      />
                    </svg>
                    <svg
                      :if={!tenant_account.connected}
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 24 24"
                      fill="currentColor"
                      class="size-6 text-orange-500"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M9.401 3.003c1.155-2 4.043-2 5.197 0l7.355 12.748c1.154 2-.29 4.5-2.599 4.5H4.645c-2.309 0-3.752-2.5-2.598-4.5L9.4 3.003ZM12 8.25a.75.75 0 0 1 .75.75v3.75a.75.75 0 0 1-1.5 0V9a.75.75 0 0 1 .75-.75Zm0 8.25a.75.75 0 1 0 0-1.5.75.75 0 0 0 0 1.5Z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </div>
                  <div class="flex justify-between pb-1 ml-5 mr-5">
                    <span class="font-medium">Active</span>
                    <svg
                      :if={tenant_account.active}
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 24 24"
                      fill="currentColor"
                      class="size-6 text-green-600"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M8.603 3.799A4.49 4.49 0 0 1 12 2.25c1.357 0 2.573.6 3.397 1.549a4.49 4.49 0 0 1 3.498 1.307 4.491 4.491 0 0 1 1.307 3.497A4.49 4.49 0 0 1 21.75 12a4.49 4.49 0 0 1-1.549 3.397 4.491 4.491 0 0 1-1.307 3.497 4.491 4.491 0 0 1-3.497 1.307A4.49 4.49 0 0 1 12 21.75a4.49 4.49 0 0 1-3.397-1.549 4.49 4.49 0 0 1-3.498-1.306 4.491 4.491 0 0 1-1.307-3.498A4.49 4.49 0 0 1 2.25 12c0-1.357.6-2.573 1.549-3.397a4.49 4.49 0 0 1 1.307-3.497 4.49 4.49 0 0 1 3.497-1.307Zm7.007 6.387a.75.75 0 1 0-1.22-.872l-3.236 4.53L9.53 12.22a.75.75 0 0 0-1.06 1.06l2.25 2.25a.75.75 0 0 0 1.14-.094l3.75-5.25Z"
                        clip-rule="evenodd"
                      />
                    </svg>
                    <svg
                      :if={!tenant_account.active}
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 24 24"
                      fill="currentColor"
                      class="size-6 text-orange-500"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M9.401 3.003c1.155-2 4.043-2 5.197 0l7.355 12.748c1.154 2-.29 4.5-2.599 4.5H4.645c-2.309 0-3.752-2.5-2.598-4.5L9.4 3.003ZM12 8.25a.75.75 0 0 1 .75.75v3.75a.75.75 0 0 1-1.5 0V9a.75.75 0 0 1 .75-.75Zm0 8.25a.75.75 0 1 0 0-1.5.75.75 0 0 0 0 1.5Z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </div>
                </div>
              </:card_body>
              <:card_actions class="justify-end">
                <div :if={!tenant_account.active and !tenant_account.connected} class="h-12">
                </div>
                <button
                  class="btn btn-primary flex items-center gap-2"
                  :if={tenant_account.active and tenant_account.connected}
                >
                  Chat
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    class="size-6"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M4.804 21.644A6.707 6.707 0 0 0 6 21.75a6.721 6.721 0 0 0 3.583-1.029c.774.182 1.584.279 2.417.279 5.322 0 9.75-3.97 9.75-9 0-5.03-4.428-9-9.75-9s-9.75 3.97-9.75 9c0 2.409 1.025 4.587 2.674 6.192.232.226.277.428.254.543a3.73 3.73 0 0 1-.814 1.686.75.75 0 0 0 .44 1.223ZM8.25 10.875a1.125 1.125 0 1 0 0 2.25 1.125 1.125 0 0 0 0-2.25ZM10.875 12a1.125 1.125 0 1 1 2.25 0 1.125 1.125 0 0 1-2.25 0Zm4.875-1.125a1.125 1.125 0 1 0 0 2.25 1.125 1.125 0 0 0 0-2.25Z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </button>
              </:card_actions>
            </.card>
          <% end %>
        </div>

        <.card :if={length(@tenant_accounts) == 0} class="bg-base-100 w-96 shadow-xl ml-10">
          <figure>
            <img src="/images/5592274.jpg" alt="Shoes" />
          </figure>
          <:card_title>Hi {@current_user.name}!</:card_title>
          <:card_body>
            <p>Quick start and connect with your Meta account</p>
          </:card_body>
          <:card_actions class="justify-end">
            <button class="btn btn-primary" phx-hook="PartnerMetaLogin" id="connectid">
              Connect your number
            </button>
          </:card_actions>
        </.card>

        <p>Session info response:</p>
        <pre id="session-info-response"></pre>

        <p>SDK response:</p>
        <pre id="sdk-response"></pre>

        <.card :if={@tenant_account} class="bg-base-100 w-96 shadow-xl ml-10">
          <:card_title>Account</:card_title>
          <:card_body>
            <p>phone_number_id: {@tenant_account.phone_number_id}</p>
            <p>waba_id: {@tenant_account.waba_id}</p>
            <p>
              token_exchange_code:
              <span :if={!@tenant_account.token_exchange_code}><.loading shape="dots" /></span>
              <span :if={@tenant_account.token_exchange_code}>
                {@tenant_account.token_exchange_code}
              </span>
            </p>
            <p>
              access_token: <span :if={!@access_token}><.loading shape="dots" /></span>
              <span :if={@access_token}>{@access_token}</span>
            </p>
          </:card_body>
        </.card>

        <script async defer crossorigin="anonymous" src="https://connect.facebook.net/en_US/sdk.js">
        </script>

        <%!-- END CONTENT --%>
      </:drawer_content>
      <:drawer_side class="h-full absolute border-r">
        <.menu class="bg-base-100 text-base-content min-h-full w-80 p-4">
          <:item>
            <h2 class="menu-title">Welcome</h2>
            <a class="active"><.icon name="hero-home" />Home</a>
          </:item>
          <:item>
            <details open>
              <summary><.icon name="hero-user" />Users</summary>
              <ul>
                <li><a><.icon name="hero-list-bullet" />List</a></li>
                <li><a><.icon name="hero-plus" />Create</a></li>
              </ul>
            </details>
          </:item>
          <:item><a><.icon name="hero-chart-bar" />Results</a></:item>
        </.menu>
      </:drawer_side>
    </.drawer>
    """
  end
end
