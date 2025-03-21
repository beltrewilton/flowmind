defmodule FlowmindWeb.DashboardLive do
  alias Flowmind.Accounts
  use FlowmindWeb, :live_view

  def doc do
    "Dashboard"
  end

  @impl true
  def mount(_params, _session, socket) do
    tenant = Flowmind.TenantGenServer.get_tenant()

    socket =
      socket
      |> assign(:tenant, tenant)
      |> assign(:tenant_account, nil)
      |> assign(:oauth_response, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("fb_login_success", %{"response" => response}, socket) do
    IO.inspect(response, label: "Facebook Login Response")
    token_exchange_code = response["response"]["authResponse"]["code"]
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

    {:ok, tenant_account} =
      Accounts.update_tenant_account(tenant_account, %{
        "token_exchange_code" => token_exchange_code
      })
      
    {_, oauth_response} = WhatsappElixir.Messages.oauth_access_token(token_exchange_code)

    socket =
      socket
      |> assign(:tenant_account, tenant_account)
      |> assign(:oauth_response, oauth_response)

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

        <.card class="bg-base-100 w-96 shadow-xl ml-10">
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
              <span :if={!@tenant_account.token_exchange_code}><.loading shape="dots"/></span>
              <span :if={@tenant_account.token_exchange_code}>{@tenant_account.token_exchange_code}</span>
            </p>
            <p>
              oauth_response: 
              <span :if={!@oauth_response}><.loading shape="dots"/></span>
              <span :if={@oauth_response}>{@oauth_response}</span>
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
