defmodule FlowmindWeb.ChatLive do
  use FlowmindWeb, :live_view

  alias Flowmind.Chat
  alias Phoenix.PubSub
  alias Flowmind.Chat.ChatHistory
  alias FlowmindWeb.ChatPubsub

  def doc do
    "Chat"
  end

  @impl true
  def mount(params, _session, socket) do
    IO.inspect(params, label: "mount init")
    sender_phone_number = Map.get(params, "sender_phone_number")
    phone_number_id = Map.get(params, "phone_number_id")

    if connected?(socket), do: ChatPubsub.subscribe(sender_phone_number)

    if connected?(socket), do: ChatPubsub.subscribe(phone_number_id)

    chat_inbox = Chat.list_chat_inbox()

    form_source = Chat.change_chat_history(%ChatHistory{})

    tenant = Flowmind.TenantGenServer.get_tenant()

    socket =
      socket
      |> assign(:chat_history, [])
      |> assign(:chat_inbox, chat_inbox)
      |> assign(:tenant, tenant)
      |> assign(:tenant_accounts, [])
      |> assign(:phone_number_id, phone_number_id)
      |> assign(:sender_phone_number, sender_phone_number)
      |> assign(:old_sender_phone_number, sender_phone_number)
      |> assign(:uploaded_files, [])
      |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png .wav .mp4 .pdf), max_entries: 2)
      |> assign_form(form_source)
      |> push_event("scrolldown", %{value: 1})

    {:ok, socket, layout: {FlowmindWeb.ChatLayouts, :app}}
  end

  @impl true
  def handle_event("send", entry_form, socket) do
    chat_entry_form = Map.get(entry_form, "chat_entry_form")

    IO.inspect(entry_form, label: "entry_form")

    sender_phone_number = socket.assigns.sender_phone_number
    phone_number_id = socket.assigns.phone_number_id

    uploaded_files =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
        client_name = entry.client_name
        dest = Path.join([:code.priv_dir(:flowmind), "static", "images", "uploads", client_name])
        File.cp!(path, dest)
        {:ok, "#{File.cwd!()}/priv/static/images/uploads/#{Path.basename(dest)}"}
      end)

    IO.inspect(uploaded_files, label: "uploaded_files")

    message_type =
      case uploaded_files do
        [] ->
          WhatsappElixir.Messages.send_message(
            sender_phone_number,
            phone_number_id,
            chat_entry_form["message"],
            WhatsappElixir.Messages.get_config()
          )

          "text"

        # TODO: must be a lot of files.
        filenames ->
          media_type = MIME.from_path(Enum.at(filenames, 0)) |> String.split("/") |> Enum.at(0)

          IO.inspect(MIME.from_path(Enum.at(filenames, 0)), label: "MIME Type")

          {_, filename} =
            if media_type == "audio" do
              WhatsappElixir.MediaDl.wav_to_ogg(Enum.at(filenames, 0))
            else
              {:ok, Enum.at(filenames, 0)}
            end

          {_, %{"id" => media_id}} =
            WhatsappElixir.MediaDl.upload(phone_number_id, filename)

          IO.inspect(media_id, label: "media_id")
          IO.inspect(media_type, label: "media_type")

          WhatsappElixir.Messages.send_media_message(
            sender_phone_number,
            phone_number_id,
            media_id,
            media_type,
            WhatsappElixir.Messages.get_config(),
            chat_entry_form["message"]
          )

          media_type
      end

    chat_entry_form =
      chat_entry_form
      |> Map.put("source", :agent)
      |> Map.put("sender_phone_number", sender_phone_number)

    chat_entry_form =
      if length(uploaded_files) > 0 do
        basename = Path.basename(Enum.at(uploaded_files, 0))

        chat_entry_form
        |> Map.put("caption", Map.get(chat_entry_form, "message", ":)"))
        |> Map.put("message", "/images/uploads/#{basename}")
        |> Map.put("message_type", message_type)
      else
        chat_entry_form
      end

    Chat.create_chat_history(chat_entry_form)
    |> ChatPubsub.notify(:message_created, sender_phone_number)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", chat_entry_form, socket) do
    IO.inspect(chat_entry_form, label: "chat_entry_form")
    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_doc_handler", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  @impl true
  def handle_event("upload_handler", entry_form, socket) do
    IO.inspect(entry_form, label: "upload_handler")

    accept =
      case entry_form do
        %{"filetype" => "image"} -> ~w(.jpg .jpeg .png)
        %{"filetype" => "audio"} -> ~w(.wav .mp3)
        %{"filetype" => "video"} -> ~w(.mp4)
        %{"filetype" => "document"} -> ~w(.pdf)
      end

    socket =
      socket
      |> allow_upload(:avatar, accept: accept, max_entries: 2)
      |> push_event("fire_file_chooser", %{value: 1})

    {:noreply, socket}
  end

  @impl true
  def handle_info({:message_created, message}, socket) do
    IO.inspect("No acredito!", label: "WOW")
    chat_history = socket.assigns.chat_history ++ [message]

    socket =
      socket
      |> assign(chat_history: chat_history)
      |> push_event("scrolldown", %{value: 1})

    {:noreply, socket}
  end
  
  @impl true
  def handle_info({:notify_message_delivered, message}, socket) do
    chat_history = socket.assigns.chat_history

    chat_history = List.update_at(chat_history, -1, fn _ -> message end)

    socket =
      socket
      |> assign(chat_history: chat_history)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:notify_message_readed, message}, socket) do
    IO.inspect(message, label: "notify_message_readed")

    chat_history = socket.assigns.chat_history

    chat_history = List.update_at(chat_history, -1, fn _ -> message end)

    socket =
      socket
      |> assign(chat_history: chat_history)
      # |> push_event("scrolldown", %{value: 1})

    {:noreply, socket}
  end

  @impl true
  def handle_info({:refresh_inbox, message}, socket) do
    # chat_inbox = socket.assigns.chat_inbox ++ [message]
    chat_inbox = Chat.list_chat_inbox()
    current_path = socket.assigns.current_path
    chat_history = socket.assigns.chat_history

    sender_phone_number = message.sender_phone_number
    phone_number_id = message.phone_number_id
    IO.inspect(current_path, label: "handle_info current_path")
    IO.inspect(sender_phone_number, label: "handle_info sender_phone_number")

    is_active_number? = String.contains?(current_path, sender_phone_number)

    chat_inbox =
      if is_active_number?,
        do: as_readed(chat_inbox, sender_phone_number, chat_history, phone_number_id),
        else: chat_inbox

    phone_number_id = message.phone_number_id

    IO.inspect(message, label: "refresh_inbox chat_inbox")

    socket =
      socket
      |> assign(chat_inbox: chat_inbox)
      |> assign(phone_number_id: phone_number_id)

    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    sender_phone_number = params["sender_phone_number"]
    old_sender_phone_number = socket.assigns.old_sender_phone_number
    phone_number_id = socket.assigns.phone_number_id
    chat_inbox = socket.assigns.chat_inbox

    IO.inspect(DateTime.utc_now(), label: "DateTime.utc_now()")
    IO.inspect(sender_phone_number, label: "sender_phone_number")
    IO.inspect(old_sender_phone_number, label: "old_sender_phone_number")

    inbox = Enum.find(chat_inbox, fn chat -> chat.sender_phone_number == sender_phone_number end)

    IO.inspect(inbox, label: "inbox")

    chat_history = Chat.list_chat_history(sender_phone_number)

    was_readed = if is_nil(inbox), do: true, else: inbox.readed

    chat_inbox =
      chat_inbox |> as_readed(sender_phone_number, chat_history, phone_number_id, was_readed)

    if !is_nil(inbox), do: Chat.update_chat_inbox(inbox, %{"readed" => true})

    if connected?(socket) do
      ChatPubsub.unsubscribe(old_sender_phone_number)
      ChatPubsub.subscribe(sender_phone_number)
    end

    # IO.inspect(chat_history, label: "chat_history")

    socket =
      socket
      |> assign(:chat_inbox, chat_inbox)
      |> assign(:chat_history, chat_history)
      |> assign(:sender_phone_number, sender_phone_number)
      |> assign(:old_sender_phone_number, sender_phone_number)
      |> push_event("scrolldown", %{value: 1})
      |> push_event("focus_on_input_text", %{value: 1})

    {:noreply, socket}
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "chat_entry_form"))
  end

  defp as_readed(
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-[90vh]">
      <div class="w-[100%]  overflow-y-auto" id="chat-messages" phx-hook="ScrolltoBottom">
        <%= for chat <- @chat_history do %>
          <% chat_css = if chat.source == :user, do: "chat-start", else: "chat-end"
          face = if chat.source == :user, do: "face1", else: "face2" %>
          <div class={"chat m-5 #{chat_css}"}>
            <div class="chat-image avatar">
              <div class="w-10 rounded-full">
                <img src={"/images/#{face}.jpg"} />
              </div>
            </div>
            <div class="chat-header">
              {chat.sender_phone_number}
              <time class="text-xs opacity-50">{NaiveDateTime.to_time(chat.inserted_at)}</time>
            </div>
            <div :if={chat.message_type == "text"} class="chat-bubble">{chat.message}</div>
            <div :if={chat.message_type == "application"} class="chat-bubble">
              <.icon name="hero-document-text" /> {chat.message}
            </div>
            <div :if={chat.message_type == "image"} class="chat-bubble">
              <img
                src={chat.message}
                alt=""
                class="max-w-xs md:max-w-sm lg:max-w-md w-auto h-auto rounded-lg shadow-md object-cover"
              />
              <span :if={!is_nil(chat.caption)} class=" text-sm py-1 rounded-lg">{chat.caption}</span>
            </div>
            <div :if={chat.message_type == "sticker"} class="chat-bubble">
              <img
                src={chat.message}
                alt=""
                class="w-16 h-16 md:w-20 md:h-20 lg:w-24 lg:h-24 rounded-md shadow-sm object-cover"
              />
              <span :if={!is_nil(chat.caption)} class=" text-sm py-1 rounded-lg">{chat.caption}</span>
            </div>
            <div :if={chat.message_type == "audio"} class="chat-bubble">
              <audio controls class="appearance-none bg-transparent">
                <source src={chat.message} type="audio/mpeg" />
                Your browser does not support the audio element.
              </audio>
            </div>
            <div :if={chat.message_type == "video"} class="chat-bubble">
              <video controls class="w-64 h-auto md:w-80 lg:w-96 rounded-lg shadow-md">
                <source src={chat.message} type="video/mp4" />
                Your browser does not support the video element.
              </video>
              <span :if={!is_nil(chat.caption)} class=" text-sm py-1 rounded-lg">{chat.caption}</span>
            </div>
            <div class="chat-footer opacity-50">
              <div :if={chat.readed and chat.delivered}>
                <.icon name="hero-check" class="h-5 w-5 text-green-600" />
                <.icon name="hero-check" class="h-5 w-5 text-green-600 -ml-5" />
              </div>
              <.icon :if={!chat.readed and chat.delivered} name="hero-check" class="h-5 w-5 text-green-600" />
              <.icon :if={!chat.readed and !chat.delivered} name="hero-check" class="h-5 w-5 text-gray-500" />
            </div>
          </div>
        <% end %>
      </div>

      <div class="flex w-[100%] bg-gray-700 p-4 rounded-lg shadow-lg">
        <.simple_form
          for={@form}
          id="chat-form"
          phx-submit="send"
          phx-change="validate"
          class="grid grid-cols-[85%_15%] gap-2 w-full mt-0"
        >
          <div class="relative h-12">
            <.input
              phx-hook="FocusOnInputText"
              field={@form[:message]}
              type="text"
              placeholder="Type a message..."
              class="w-full border border-gray-500 bg-gray-800 text-white focus:ring-2 focus:ring-blue-500 pr-8"
            />

            <.live_file_input upload={@uploads.avatar} class="hidden live_file_input" />

            <div :for={entry <- @uploads.avatar.entries} class="absolute cursor-pointer left-10 top-0 transform -translate-y-1/2 text-white">
              <.badge color="neutral" class="p-3">
                <.icon name="hero-document-check" class="text-xs"/>
                {entry.client_name}
                <div id="close-doc-id" phx-click="remove_doc_handler" phx-value-ref={entry.ref} >
                  <.icon name="hero-x-mark" class="text-xs"/>
                </div>
              </.badge>
            </div>

            <.dropdown direction="top" class="absolute cursor-pointer left-3 top-0 transform -translate-y-1/2 ">
              <div id="clip-id" tabindex="0" class="text-white m-1" phx-hook="FileChooser"  >
                <.icon name="hero-paper-clip" />
              </div>
              <.menu tabindex="0" class="dropdown-content">
                <:item>
                  <label
                    id="image-label-id"
                    for="file-upload"
                    phx-click="upload_handler"
                    phx-value-filetype="image"
                  >
                    <.icon name="hero-camera" />
                  </label>
                </:item>
                <:item>
                  <label
                    id="audio-label-id"
                    for="file-upload"
                    phx-click="upload_handler"
                    phx-value-filetype="audio"
                  >
                    <.icon name="hero-microphone" />
                  </label>
                </:item>
                <:item>
                  <label
                    id="video-label-id"
                    for="file-upload"
                    phx-click="upload_handler"
                    phx-value-filetype="video"
                  >
                    <.icon name="hero-video-camera" />
                  </label>
                </:item>
                <:item>
                  <label
                    id="document-label-id"
                    for="file-upload"
                    phx-click="upload_handler"
                    phx-value-filetype="document"
                  >
                    <.icon name="hero-document" />
                  </label>
                </:item>
              </.menu>
            </.dropdown>

          </div>

          <:actions>
            <.button
              phx-disable-with="sending..."
              class="w-full mt-2 px-4 py-2 bg-blue-500 text-white hover:bg-blue-600 transition duration-300 "
            >
              <.icon name="hero-paper-airplane" />
            </.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end
end
