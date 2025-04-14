defmodule FlowmindWeb.NotAuthorized do
  use FlowmindWeb, :live_view

  def doc do
    "NotAuthorized"
  end

  @impl true
  def mount(params, session, socket) do
    tenant = Flowmind.TenantContext.get_tenant()

    socket =
      socket
      |> assign(:tenant, tenant)
      |> assign(:tenant_accounts, [])

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center h-full w-full">
      
      <.alert color="error" id="alert-single-alert-with-title-and-description">
        <.icon name="hero-exclamation-circle" />
        <div>
          <h3 class="font-bold text-xl">Not Authorized</h3>
          <div  class="text-xs"></div>
        </div>

      </.alert>

    </div>
    """
  end
end
