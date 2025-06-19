defmodule FlowmindWeb.Live.InputIconComponent do
  use FlowmindWeb, :live_component
  # use Phoenix.LiveComponent
  attr :itype, :string, default: "text"
  attr :iid, :string, default: UUID.uuid4()

  def render(assigns) do
    ~H"""
    <div class="">
      <.icon name={@icon_name} class="absolute mt-9 ml-2 z-10" />
      <.input
        id={@iid}
        label={@ilabel}
        field={@form[@formvar]}
        type={@itype}
        class="pl-10"
        placeholder={@ilabel}
        required
      />
    </div>
    """
  end
end
