defmodule FlowmindWeb.DashboardLive do
  use FlowmindWeb, :live_view

  def doc do
    "Dashboard"
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
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
                  <.link
                    href={~p"/users/log_out"}
                    method="delete"
                  >
                    Log out
                  </.link>
                </:item>
              </.menu>
            </.dropdown>
          </div>
        </.navbar>
        
        <%!-- CONTENT HERE --%>
       
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
