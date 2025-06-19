defmodule FlowmindWeb.DemoLive do
  use FlowmindWeb, :live_view

  alias Flowmind.Accounts

  def render(assigns) do
    ~H"""
    <h1>Demo {@tenant_info}</h1>
    <.table id="tenants" rows={@list_tenants}>
      <:col :let={tenant} label="phone_number_id">{tenant.phone_number_id}</:col>
      <:col :let={tenant} label="waba_id">{tenant.waba_id}</:col>
    </.table>
    <.range max={100} min={0} value={40} />
    """
  end

  def mount(_params, _session, socket) do
    list_tenants = Accounts.list_tenant_accounts()
    tenant_info = Flowmind.TenantContext.get_tenant()
    socket = assign(socket, :list_tenants, list_tenants)
    socket = assign(socket, :tenant_info, tenant_info)
    {:ok, socket}
  end
end
