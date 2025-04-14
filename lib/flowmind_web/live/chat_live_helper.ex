defmodule FlowmindWeb.ChatLiveHelper do
  alias Flowmind.Chat

  def refresh_inbox(message, socket) do
    # chat_inbox = socket.assigns.chat_inbox ++ [message]
    current_user = socket.assigns.current_user
    chat_inbox = Chat.list_chat_inbox(current_user)
    current_path = socket.assigns.current_path
    chat_history = socket.assigns.chat_history
    {_, message} = message
  
    sender_phone_number = message.sender_phone_number
    phone_number_id = message.phone_number_id
    # IO.inspect(current_path, label: "handle_info current_path")
    # IO.inspect(sender_phone_number, label: "handle_info sender_phone_number")

    is_active_number? = String.contains?(current_path, sender_phone_number)

    chat_inbox =
      if is_active_number?,
        do: as_readed(chat_inbox, sender_phone_number, chat_history, phone_number_id),
        else: chat_inbox

    phone_number_id = message.phone_number_id

    IO.inspect(message, label: "refresh_inbox chat_inbox")
    
    inbox = Enum.find(chat_inbox, fn chat -> chat.sender_phone_number == sender_phone_number end)

    socket =
      socket
      |> Phoenix.Component.assign(chat_inbox: chat_inbox)
      |> Phoenix.Component.assign(:alias_name, inbox.alias)
      |> Phoenix.Component.assign(phone_number_id: phone_number_id)
      
    {:noreply, socket}
  end

  def as_readed(
         chat_inbox,
         sender_phone_number,
         chat_history,
         phone_number_id,
         was_readed \\ false
       ) do
    chat_inbox =
      Enum.map(chat_inbox, fn chat ->
        if chat.sender_phone_number == sender_phone_number do
          if length(chat_history) > 0 and !was_readed do
            chat = List.last(chat_history)
            send_readed(chat.whatsapp_id, phone_number_id)
          end

          %{chat | readed: true}
        else
          chat
        end
      end)
  end

  defp send_readed(message_id, phone_number_id) do
    WhatsappElixir.Messages.mark_as_read(
      message_id,
      phone_number_id,
      WhatsappElixir.Messages.get_config()
    )
  end
end
