defmodule FlowmindWeb.HookedEventLive do
  use FlowmindWeb, :live_view

  alias Flowmind.Accounts

  def render(assigns) do
    ~H"""
    HookedEventLive
    """
  end

  def mount(_params, _session, socket) do
    IO.inspect("hooked_event mount")
    {:ok, socket}
  end

  def hooked_event("shuffle", param, socket) do
    IO.inspect(param, label: "hooked_event shuffle")
    {:halt, socket}
  end

  def hooked_event("sort", param, socket) do
    IO.inspect(param, label: "hooked_event sort")

    {:halt, socket}
  end

  def hooked_event(_event, _params, socket), do: {:cont, socket}
end
