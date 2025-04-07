defmodule FlowmindWeb.ChatThumbnail do
  use FlowmindWeb, :live_component

  def render(assigns) do
    ~H"""
    <div >
      <div :if={@chat.message_type == "text"} >
        {@chat.message}
      </div>
      <div :if={@chat.message_type == "application"} >
        <canvas id="the-canvas-2" phx-hook="PdfPreview" data-docurl={@chat.message} data-scale={0.2}></canvas>
        <.icon name="hero-document-text" /> {Path.basename(@chat.message)}
      </div>
      <div :if={@chat.message_type == "image"} >
        <img
          src={@chat.message}
          alt=""
          class="w-24 h-24 object-cover rounded-md shadow-sm"
        />
      </div>
      <div :if={@chat.message_type == "sticker"} >
        <img
          src={@chat.message}
          alt=""
          class="w-16 h-16 md:w-20 md:h-20 lg:w-24 lg:h-24 object-cover rounded-md shadow-sm"
        />
      </div>
      <div :if={@chat.message_type == "audio"} >
        <audio controls class="appearance-none bg-transparent">
          <source src={@chat.message} type="audio/mpeg" />
          Your browser does not support the audio element.
        </audio>
      </div>
      <div :if={@chat.message_type == "video"} >
        <video controls <video controls class="w-32 h-20 md:w-40 md:h-24 lg:w-48 lg:h-28 rounded-md shadow-sm object-cover">
          <source src={@chat.message} type="video/mp4" />
          Your browser does not support the video element.
        </video>
      </div>
    </div>
    """
  end
end
