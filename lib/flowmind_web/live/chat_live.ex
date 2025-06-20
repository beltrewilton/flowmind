defmodule FlowmindWeb.ChatLive do
  use FlowmindWeb, :live_view

  alias Flowmind.Organization
  alias Flowmind.Chat
  alias Phoenix.PubSub
  alias Flowmind.Chat.ChatHistory
  alias FlowmindWeb.ChatPubsub
  alias FlowmindWeb.ChatLiveHelper

  def doc do
    "Chat"
  end

  @impl true
  def mount(params, _session, socket) do
    IO.inspect(params, label: "mount init")
    sender_phone_number = Map.get(params, "sender_phone_number")
    phone_number_id = Map.get(params, "phone_number_id")

    if connected?(socket), do: ChatPubsub.subscribe(sender_phone_number, phone_number_id)

    if connected?(socket), do: ChatPubsub.subscribe(phone_number_id)

    chat_inbox = socket.assigns.chat_inbox
    # chat_inbox = Chat.list_chat_inbox(current_user)
    inbox = Enum.find(chat_inbox, fn chat -> chat.sender_phone_number == sender_phone_number end)

    form_source = Chat.change_chat_history(%ChatHistory{})

    tenant = Flowmind.TenantContext.get_tenant()

    socket =
      socket
      |> assign(:chat_history, [])
      |> assign(:chat_inbox, chat_inbox)
      |> assign(:chat_pinned, nil)
      |> assign(:tenant, tenant)
      |> assign(:tenant_accounts, [])
      |> assign(:phone_number_id, phone_number_id)
      |> assign(:sender_phone_number, sender_phone_number)
      |> assign(:old_sender_phone_number, sender_phone_number)
      |> assign(:uploaded_files, [])
      |> assign(:edit_alias, false)
      |> assign(:alias_name, inbox.alias)
      |> assign(:country, CountryLookup.lookup_by_code(sender_phone_number))
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
        dest = Path.join([File.cwd!(), "uploads", client_name])
        File.cp!(path, dest)
        {:ok, "#{File.cwd!()}/uploads/#{Path.basename(dest)}"}
      end)

    ref_whatsapp_id =
      cond do
        socket.assigns[:chat_pinned] != nil ->
          IO.inspect(socket.assigns.chat_pinned.whatsapp_id, label: "ref_whatsapp_id")
          socket.assigns.chat_pinned.whatsapp_id

        true ->
          IO.inspect("== nil", label: "ref_whatsapp_id")
          nil
      end

    {message_type, response} =
      case uploaded_files do
        [] ->
          {_, response} =
            WhatsappElixir.Messages.send_message(
              sender_phone_number,
              phone_number_id,
              chat_entry_form["message"],
              WhatsappElixir.Messages.get_config(),
              ref_whatsapp_id
            )

          {"text", response}

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

          {_, response} =
            WhatsappElixir.Messages.send_media_message(
              sender_phone_number,
              phone_number_id,
              media_id,
              media_type,
              WhatsappElixir.Messages.get_config(),
              chat_entry_form["message"]
            )

          {media_type, response}
      end

    IO.inspect(response, label: "response")

    whatsapp_id = WhatsappElixir.Static.get_response_message_id(response)

    chat_entry_form =
      chat_entry_form
      |> Map.put("source", :agent)
      |> Map.put("sender_phone_number", sender_phone_number)
      |> Map.put("whatsapp_id", whatsapp_id)
      |> Map.put("ref_whatsapp_id", ref_whatsapp_id)

    chat_entry_form =
      if length(uploaded_files) > 0 do
        basename = Path.basename(Enum.at(uploaded_files, 0))

        chat_entry_form
        |> Map.put("caption", Map.get(chat_entry_form, "message", ":)"))
        |> Map.put("message", "/uploads/#{basename}")
        |> Map.put("message_type", message_type)
      else
        chat_entry_form
      end

    Chat.create_chat_history(chat_entry_form)
    |> ChatPubsub.notify(:message_created, sender_phone_number, phone_number_id)

    socket =
      socket
      |> assign(:chat_pinned, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", chat_entry_form, socket) do
    IO.inspect(chat_entry_form, label: "chat_entry_form")
    {:noreply, socket}
  end

  @impl true
  def handle_event("handle_repply", chat_entry_form, socket) do
    chat_history = socket.assigns.chat_history
    whatsapp_id = Map.get(chat_entry_form, "whatsapp_id")

    chat_pinned =
      Enum.find(chat_history, fn chat ->
        chat.whatsapp_id == whatsapp_id
      end)

    IO.inspect(chat_pinned, label: "chat_pinned")

    socket =
      socket
      |> assign(:chat_pinned, chat_pinned)
      |> push_event("scrolldown", %{value: 1})
      |> push_event("focus_on_input_text", %{value: 1})

    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_chat_pinned", chat_entry_form, socket) do
    socket =
      socket
      |> assign(:chat_pinned, nil)
      |> push_event("focus_on_input_text", %{value: 1})

    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_doc_handler", %{"ref" => ref}, socket) do
    socket =
      socket
      |> push_event("focus_on_input_text", %{value: 1})

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
  def handle_event("handle_edit_alias", entry, socket) do
    IO.inspect(entry, label: "handle_edit_alias")

    socket =
      socket
      |> assign(:edit_alias, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("handle_change_alias", entry, socket) do
    country = socket.assigns.country
    chat_inbox = socket.assigns.chat_inbox
    current_user = socket.assigns.current_user

    IO.inspect(entry, label: "handle_change_alias")
    input_value = Map.get(entry, "input_value")
    sender_phone_number = Map.get(entry, "sender_phone_number")
    IO.inspect(input_value)
    IO.inspect(sender_phone_number)
    inbox = Enum.find(chat_inbox, fn chat -> chat.sender_phone_number == sender_phone_number end)
    inbox = Chat.update_chat_inbox(inbox, %{"alias" => input_value})

    phone_number_id = socket.assigns.phone_number_id
    inbox |> ChatPubsub.notify(:refresh_inbox, phone_number_id)

    Organization.update_customer_by_phone_number(sender_phone_number, %{
      "name" => input_value,
      "country" => country.name
    })

    chat_inbox = Chat.list_chat_inbox(current_user)

    socket =
      socket
      |> assign(:alias_name, input_value)
      |> assign(:edit_alias, false)
      |> assign(:chat_inbox, chat_inbox)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:message_created, message}, socket) do
    {_, message} = message
    IO.inspect(message, label: "message_created")
    chat_history = socket.assigns.chat_history ++ [message]

    # IO.inspect(message, label: "mira -> message")
    # IO.inspect(message.chat_history, label: "mira -> message.chat_history")
    # IO.inspect(is_struct(message.chat_history), label: "mira -> is_struct")
    # IO.inspect(chat_history, label: "mira -> chat_history")

    socket =
      socket
      |> assign(chat_history: chat_history)
      |> push_event("scrolldown", %{value: 1})

    {:noreply, socket}
  end

  @impl true
  def handle_info({:notify_message_delivered, message}, socket) do
    {_, message} = message
    chat_history = socket.assigns.chat_history

    chat_history = List.update_at(chat_history, -1, fn _ -> message end)

    socket =
      socket
      |> assign(chat_history: chat_history)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:notify_message_readed, message}, socket) do
    {_, message} = message
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
    ChatLiveHelper.refresh_inbox(message, socket)
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

    # IO.inspect(chat_history, label: "chat_history")

    was_readed = if is_nil(inbox), do: true, else: inbox.readed

    chat_inbox =
      chat_inbox
      |> ChatLiveHelper.as_readed(sender_phone_number, chat_history, phone_number_id, was_readed)

    if !is_nil(inbox), do: Chat.update_chat_inbox(inbox, %{"readed" => true})

    if connected?(socket) do
      ChatPubsub.unsubscribe(old_sender_phone_number, phone_number_id)
      ChatPubsub.subscribe(sender_phone_number, phone_number_id)
    end

    # IO.inspect(chat_history, label: "chat_history")

    socket =
      socket
      |> assign(:chat_inbox, chat_inbox)
      |> assign(:chat_history, chat_history)
      |> assign(:sender_phone_number, sender_phone_number)
      |> assign(:old_sender_phone_number, sender_phone_number)
      |> assign(:alias_name, inbox.alias)
      |> assign(:country, CountryLookup.lookup_by_code(sender_phone_number))
      |> push_event("scrolldown", %{value: 1})
      |> push_event("focus_on_input_text", %{value: 1})

    {:noreply, socket}
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "chat_entry_form"))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-[90vh] w-full">
      <!-- Left Container -->
      <div id="left-container" class="flex flex-col w-2/3">
        <div class="w-full overflow-y-auto flex-1" id="chat-messages" phx-hook="ScrolltoBottom">
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

              <.live_component
                module={FlowmindWeb.ChatBubbleContent}
                id={"live-component-#{chat.id}-#{UUID.uuid1()}"}
                chat={chat}
              />

              <div :if={chat.source != :user} class="chat-footer opacity-50">
                <div :if={chat.readed and chat.delivered}>
                  <.icon name="hero-check" class="h-5 w-5 text-blue-700" />
                  <.icon name="hero-check" class="h-5 w-5 text-blue-700 -ml-5" />
                </div>
                <.icon
                  :if={!chat.readed and chat.delivered}
                  name="hero-check"
                  class="h-5 w-5 text-blue-700"
                />
                <.icon
                  :if={!chat.readed and !chat.delivered}
                  name="hero-check"
                  class="h-5 w-5 text-gray-500"
                />
              </div>
            </div>
          <% end %>
        </div>

        <div class="flex flex-col w-full bg-gray-700 p-4 rounded-lg shadow-lg">
          <div :if={@chat_pinned} class="chat chat-start mb-3 ml-12">
            <div class="flex flex-row chat-bubble border-r-4 border-blue-500">
              <.live_component
                module={FlowmindWeb.ChatThumbnail}
                id={"pi-app-live-component-#{@chat_pinned.id}"}
                chat={@chat_pinned}
              />
              <div phx-click="remove_chat_pinned">
                <.icon name="hero-x-mark" class="text-xs cursor-pointer" />
              </div>
            </div>
          </div>
          <.simple_form
            for={@form}
            id="chat-form"
            phx-submit="send"
            phx-change="validate"
            class="grid grid-cols-[85%_15%] gap-2 w-full mt-0"
          >
            <div class="relative h-12">
              <.input
                id="chat-input"
                phx-hook="FocusOnInputText"
                field={@form[:message]}
                type="text"
                placeholder="Type a message..."
                class="w-full border border-gray-500 bg-gray-800 text-white focus:ring-2 focus:ring-blue-500 pr-8"
              />

              <.live_file_input upload={@uploads.avatar} class="hidden live_file_input" />

              <div
                :for={entry <- @uploads.avatar.entries}
                class="absolute cursor-pointer left-10 top-0 transform -translate-y-1/2 text-white"
              >
                <.badge color="neutral" class="p-3">
                  <.icon name="hero-document-check" class="text-xs" />
                  {entry.client_name}
                  <div id="close-doc-id" phx-click="remove_doc_handler" phx-value-ref={entry.ref}>
                    <.icon name="hero-x-mark" class="text-xs" />
                  </div>
                </.badge>
              </div>

              <.dropdown
                direction="top"
                class="absolute cursor-pointer left-3 top-0 transform -translate-y-1/2 "
              >
                <div id="clip-id" tabindex="0" class="text-white m-1" phx-hook="FileChooser">
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
                id="send-button-id"
                phx-disable-with="sending..."
                phx-click={JS.set_attribute({"value", ""}, to: "#chat-input")}
                class="w-full mt-2 px-4 py-2 bg-blue-500 text-white hover:bg-blue-600 transition duration-300"
              >
                <.icon name="hero-paper-airplane" />
              </.button>
            </:actions>
          </.simple_form>
        </div>
      </div>
      
    <!-- Right Container -->
      <div
        id="right-container"
        class="flex flex-col w-1/3 h-full bg-gray-800 p-4 rounded-lg shadow-lg"
      >
        <h2 class="text-white text-xl mb-3">
          <.swap
            phx-click={
              JS.toggle_class("w-1/3 w-0", to: "#right-container")
              |> JS.toggle_class("w-2/3 w-full", to: "#left-container")
              |> JS.toggle_class("disapear-body", to: ".r-body")
            }
            animation="rotate"
            class="-ml-3 mb-1"
          >
            <:swap_off type="icon" name="hero-chevron-right" />
            <:swap_on type="icon" name="hero-chevron-left" />
          </.swap>
          <span class="r-body">Right Panel</span>
        </h2>
        <div class="flex-1 overflow-y-auto r-body">
          <p class="text-gray-300">You can add user list, details, or extra options here.</p>
        </div>
      </div>
    </div>
    """
  end
end
