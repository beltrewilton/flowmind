defmodule FlowmindWeb.ChatDropdown do
  use FlowmindWeb, :live_component

  def render(assigns) do
    ~H"""
    <div id={"dropdown-#{@chat.id}"}>
    <.dropdown align="end" class="absolute cursor-pointer text-gray-400 top-0 right-0">
      <.swap animation="rotate" id={"reply-#{@chat.id}"} >
        <:swap_off type="icon" name="hero-ellipsis-vertical" />
        <:swap_on type="icon" name="hero-chevron-down" />
      </.swap>
      <.menu tabindex="0" class="max-w-20 dropdown-content bg-primary text-primary-content rounded-box z-[1] w-52 p-2 shadow">
        <:item>
          <label
            id={@chat.id}
            phx-click="handle_repply"
            phx-value-whatsapp_id={@chat.whatsapp_id}
          >
          reply
          </label>
        </:item>
      </.menu>
    </.dropdown>
    </div>
    """
  end
end
