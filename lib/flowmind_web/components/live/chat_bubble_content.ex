defmodule FlowmindWeb.ChatBubbleContent do
  use FlowmindWeb, :live_component
  # use Phoenix.LiveComponent
  
  def render(assigns) do
    ~H"""
    <div id={"cb-#{@chat.id}"}>
    <div :if={is_struct(@chat.chat_history)}>
      <div :if={@chat.message_type == "text"}>
        <div class="chat-bubble border-l-4 border-l-blue-500 shadow">
          {@chat.chat_history.message}
        </div>
        <div class="mr-5">{@chat.message}</div>
      </div>
      <div :if={@chat.message_type == "application"}>
        <div class="chat-bubble border-l-4 border-l-blue-500 shadow">
          <.icon name="hero-document-text" /> {@chat.chat_history.message}
        </div>
        <div class="mr-5">{@chat.message}</div>
      </div>
      <div :if={@chat.message_type == "image"}>
        <div class="chat-bubble border-l-4 border-l-blue-500 shadow">
          <img
            src={@chat.message}
            alt=""
            class="max-w-xs md:max-w-sm lg:max-w-md w-auto h-auto rounded-lg shadow-md object-cover"
          />
          <span :if={!is_nil(@chat.chat_history.caption)} class="text-sm py-1 rounded-lg">{@chat.caption}</span>
        </div>
        <div class="mr-5">{@chat.message}</div>
      </div>
      <div :if={@chat.message_type == "sticker"}>
        <div class="chat-bubble border-l-4 border-l-blue-500 shadow">
          <img
            src={@chat.chat_history.message}
            alt=""
            class="w-16 h-16 md:w-20 md:h-20 lg:w-24 lg:h-24 rounded-md shadow-sm object-cover"
          />
          <span :if={!is_nil(@chat.chat_history.caption)} class=" text-sm py-1 rounded-lg">{@chat.caption}</span>
        </div>
        <div class="mr-5">{@chat.message}</div>
      </div>
      <div :if={@chat.message_type == "audio"}>
        <div class="chat-bubble border-l-4 border-l-blue-500 shadow">      
          <audio controls class="appearance-none bg-transparent">
            <source src={@chat.chat_history.message} type="audio/mpeg" />
            Your browser does not support the audio element.
          </audio>
        </div>
        <div class="mr-5">{@chat.message}</div>
      </div>
      <div :if={@chat.message_type == "video"}>
        <div class="chat-bubble border-l-4 border-l-blue-500 shadow">      
          <video controls class="w-64 h-auto md:w-80 lg:w-96 rounded-lg shadow-md">
            <source src={@chat.chat_history.message} type="video/mp4" />
            Your browser does not support the video element.
          </video>
          <span :if={!is_nil(@chat.chat_history.caption)} class=" text-sm py-1 rounded-lg">{@chat.caption}</span>
        </div>
        <div class="mr-5">{@chat.message}</div>
      </div>
    </div>
    
    <.dropdown direction="bottom" class="absolute cursor-pointer text-gray-400 top-0 right-0">
      <.swap animation="rotate" id={"reply-#{@chat.id}"} >
        <:swap_off type="icon" name="hero-ellipsis-vertical" />
        <:swap_on type="icon" name="hero-chevron-down" />
      </.swap>
      <.menu tabindex="0" class="dropdown-content">
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
