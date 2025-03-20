defmodule FlowmindWeb.DemoLive do
  use FlowmindWeb, :live_view
  
  alias Flowmind.Operations
  
  def render(assigns) do
    ~H"""
    <h1>Demo {@tenant_info}</h1>
    <.table id="tenants" rows={@list_tenants}>
      <:col :let={tenant} label="waba">{tenant.waba}</:col>
      <:col :let={tenant} label="config">{tenant.config}</:col>
    </.table>
    <.range max={100} min={0} value={40}/>

    """
  end
  
  def mount(_params, _session, socket) do
    list_tenants = Operations.list_tenant_account()
    tenant_info = Flowmind.TenantGenServer.get_tenant()
    socket = assign(socket, :list_tenants, list_tenants)
    socket = assign(socket, :tenant_info, tenant_info)
    {:ok, socket}
  end
  
end