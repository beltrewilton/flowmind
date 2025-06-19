defmodule FlowmindWeb.AttachHookUtil do
  alias Flowmind.Accounts
  alias Phoenix.LiveView.JS
  alias Flowmind.Data.Mem

  @doc """
  Sets the path from the connection as :current_path on the socket
  """
  def on_mount(:attach_hook_util, _params, _session, socket) do
    user = socket.assigns.current_user

    width =
      if is_nil(Mem.get_user_preference(user.id, "width")),
        do: "w-80",
        else: Mem.get_user_preference(user.id, "width")

    display =
      if is_nil(Mem.get_user_preference(user.id, "display")),
        do: "block",
        else: Mem.get_user_preference(user.id, "display")

    Mem.add_user_preference(user.id, "width", width)
    Mem.add_user_preference(user.id, "display", display)

    socket =
      socket
      |> Phoenix.Component.assign(:width, width)
      |> Phoenix.Component.assign(:display, display)
      |> Phoenix.LiveView.attach_hook(
        :toggle_drawer,
        :handle_event,
        &toggle_drawer_event/3
      )
      |> Phoenix.LiveView.attach_hook(
        :put_path_in_socket,
        :handle_params,
        &put_path_in_socket/3
      )

    {:cont, socket}
  end

  defp put_path_in_socket(_params, url, socket) do
    current_path = URI.parse(url).path
    IO.inspect(current_path, label: "current_path")
    {:cont, Phoenix.Component.assign(socket, :current_path, current_path)}
  end

  def toggle_drawer_event("toggle_drawer", _data, socket) do
    user = socket.assigns.current_user

    width = if Mem.get_user_preference(user.id, "width") == "w-80", do: "w-12", else: "w-80"

    display =
      if Mem.get_user_preference(user.id, "display") == "block", do: "hidden", else: "block"

    Mem.add_user_preference(user.id, "width", width)
    Mem.add_user_preference(user.id, "display", display)

    # socket =
    #   socket
    #   |> Phoenix.Component.assign(:width, width)
    #   |> Phoenix.Component.assign(:display, display)

    {:halt, socket}
  end

  def toggle_drawer_event(_event, _params, socket), do: {:cont, socket}
end
