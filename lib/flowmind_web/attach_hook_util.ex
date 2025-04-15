defmodule FlowmindWeb.AttachHookUtil do
  alias Flowmind.Accounts
  
  @doc """
  Sets the path from the connection as :current_path on the socket
  """
  def on_mount(:attach_hook_util, _params, _session, socket) do
    current_user = socket.assigns.current_user
    default_attrs = %{"preference" => %{"expanded" => true, "expanded_w" => "w-80"}}
    {:ok, current_user} = if is_nil(current_user.preference), do: Accounts.update_user_preference(current_user, default_attrs), else: {:ok, current_user}
    
    socket =
      socket
      |> Phoenix.Component.assign(:current_user, current_user)
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
    current_user = socket.assigns.current_user
    preference = current_user.preference || %{}
    IO.inspect(preference, label: "Preference")
    expanded = Map.get(preference, "expanded", false)
    expanded_w = Map.get(preference, "expanded_w", "w-80")

    new_expanded = !expanded
    new_expanded_w = if expanded_w == "w-80", do: "w-15", else: "w-80"

    attrs = %{"preference" => %{"expanded" => new_expanded, "expanded_w" => new_expanded_w}}

    {:ok, current_user} = Accounts.update_user_preference(current_user, attrs)

    socket =
      socket
      |> Phoenix.Component.assign(:current_user, current_user)

    {:halt, socket}
  end
  
  def toggle_drawer_event(_event, _params, socket), do: {:cont, socket}
end
