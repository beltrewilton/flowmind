defmodule FlowmindWeb.AnotherLive do
  use FlowmindWeb, :live_view

  def doc do
    "Another"
  end

  @impl true
  def mount(_params, _session, socket) do
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
    <div class="flex flex-col items-center gap-5 w-full">
      <.input id="input-basic-inputs-text" placeholder="Text input" type="text" />
      <.input id="input-basic-inputs-textarea" placeholder="Textarea input" type="textarea" />
      <.input id="input-basic-inputs-number" placeholder="Number input" type="number" />
      <.input id="input-basic-inputs-date" placeholder="Date input" type="date" />
      <.input id="input-basic-inputs-color" placeholder="Color input" type="color" />
      <.input id="input-basic-inputs-range" placeholder="Range input" type="range" />
      <.input id="input-basic-inputs-checkbox" placeholder="Checkbox input" type="checkbox" />
      <.input id="input-basic-inputs-radio" placeholder="Radio input" type="radio" />
    </div>
    """
  end
end
