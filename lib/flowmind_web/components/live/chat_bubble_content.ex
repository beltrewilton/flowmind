defmodule FlowmindWeb.ChatBubbleContent do
  use FlowmindWeb, :live_component
  # use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div id={"chat-bubble-#{@chat.id}"}>
      <div :if={@chat.message_type == "text"} class="chat-bubble relative">
        <div :if={is_struct(@chat.chat_history)} class="chat-bubble border-l-4 border-l-blue-500 shadow">
          <.live_component
            module={FlowmindWeb.ChatThumbnail}
            id={"th-text-live-component-#{@chat.id}"}
            chat={@chat.chat_history} />
        </div>
        <div class="mr-5">{@chat.message}</div>
        <.live_component
          module={FlowmindWeb.ChatDropdown}
          id={"dd-live-component-#{@chat.id}"}
          chat={@chat} />
      </div>

      <div :if={@chat.message_type == "application"} class="chat-bubble relative">
        <div :if={is_struct(@chat.chat_history)} class="chat-bubble border-l-4 border-l-blue-500 shadow">
          <.live_component
            module={FlowmindWeb.ChatThumbnail}
            id={"th-app-live-component-#{@chat.id}"}
            chat={@chat.chat_history} />
        </div>
        <.icon name="hero-document-text" /> {@chat.message}
        <.live_component
          module={FlowmindWeb.ChatDropdown}
          id={"dd-live-component-#{@chat.id}"}
          chat={@chat} />
      </div>

      <div :if={@chat.message_type == "image"} class="chat-bubble relative">
        <div :if={is_struct(@chat.chat_history)} class="chat-bubble border-l-4 border-l-blue-500 shadow">
          <.live_component
            module={FlowmindWeb.ChatThumbnail}
            id={"th-image-live-component-#{@chat.id}"}
            chat={@chat.chat_history} />
        </div>
        <img
          src={@chat.message}
          alt=""
          class="max-w-xs md:max-w-sm lg:max-w-md w-auto h-auto rounded-lg shadow-md object-cover"
        />
        <span :if={!is_nil(@chat.caption)} class=" text-sm py-1 rounded-lg">{@chat.caption}</span>
        <.live_component
          module={FlowmindWeb.ChatDropdown}
          id={"dd-live-component-#{@chat.id}"}
          chat={@chat} />
      </div>

      <div :if={@chat.message_type == "sticker"} class="chat-bubble relative">
        <div :if={is_struct(@chat.chat_history)} class="chat-bubble border-l-4 border-l-blue-500 shadow">
          <.live_component
            module={FlowmindWeb.ChatThumbnail}
            id={"th-sticker-live-component-#{@chat.id}"}
            chat={@chat.chat_history} />
        </div>
        <img
          src={@chat.message}
          alt=""
          class="w-16 h-16 md:w-20 md:h-20 lg:w-24 lg:h-24 rounded-md shadow-sm object-cover"
        />
        <span :if={!is_nil(@chat.caption)} class=" text-sm py-1 rounded-lg">{@chat.caption}</span>
        <.live_component
          module={FlowmindWeb.ChatDropdown}
          id={"dd-live-component-#{@chat.id}"}
          chat={@chat} />
      </div>

      <div :if={@chat.message_type == "audio"} class="chat-bubble relative">
        <div :if={is_struct(@chat.chat_history)} class="chat-bubble border-l-4 border-l-blue-500 shadow">
          <.live_component
            module={FlowmindWeb.ChatThumbnail}
            id={"th-audio-live-component-#{@chat.id}"}
            chat={@chat.chat_history} />
        </div>
        <audio controls class="appearance-none bg-transparent">
          <source src={@chat.message} type="audio/mpeg" />
          Your browser does not support the audio element.
        </audio>
        <.live_component
          module={FlowmindWeb.ChatDropdown}
          id={"dd-live-component-#{@chat.id}"}
          chat={@chat} />
      </div>
      
      <div :if={@chat.message_type == "video"} class="chat-bubble relative">
        <div :if={is_struct(@chat.chat_history)} class="chat-bubble border-l-4 border-l-blue-500 shadow">
          <.live_component
            module={FlowmindWeb.ChatThumbnail}
            id={"th-video-live-component-#{@chat.id}"}
            chat={@chat.chat_history} />
        </div>
        <video controls class="w-64 h-auto md:w-80 lg:w-96 rounded-lg shadow-md">
          <source src={@chat.message} type="video/mp4" />
          Your browser does not support the video element.
        </video>
        <span :if={!is_nil(@chat.caption)} class=" text-sm py-1 rounded-lg">{@chat.caption}</span>
        <.live_component
          module={FlowmindWeb.ChatDropdown}
          id={"dd-live-component-#{@chat.id}"}
          chat={@chat} />
      </div>

    </div>
    """
  end
end
