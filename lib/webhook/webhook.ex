defmodule Webhook.Router do
  use Plug.Router

  import Plug.Conn

  alias Flowmind.Chat
  alias Flowmind.Accounts
  alias FlowmindWeb.ChatPubsub

  alias Flowmind.Data.Mem

  plug(:match)
  plug(Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason)
  plug(:dispatch)

  # alias DBConnection.Task
  alias WhatsappElixir.Static, as: WS
  alias WhatsappElixir.MediaDl

  @source_webhook "WEBHOOK"

  get "/:tenant/test" do
    IO.inspect(tenant, label: "tenant")
    send_resp(conn, 200, Jason.encode!(%{"status" => "success"}))
  end

  get "/:tenant" do
    verify_token = conn.query_params["hub.verify_token"]
    local_hook_token = System.get_env("CLOUD_API_TOKEN_VERIFY")

    if verify_token == local_hook_token do
      hub_challenge = conn.query_params["hub.challenge"]
      send_resp(conn, 200, hub_challenge)
    else
      send_resp(conn, 403, "Authentication failed. Invalid Token.")
    end
  end

  post "/:tenant" do
    data = conn.body_params
    handle_notification(WS.handle_notification(data), data, tenant, conn)

    send_resp(conn, 200, Jason.encode!(%{"status" => "success"}))
  end

  # forward("/flow", to: Flow.Router)

  match _ do
    send_resp(conn, 404, "You are trying something that does not exist.")
  end

  def handle_notification(%Whatsapp.Client.Sender{} = data, rawdata, tenant, %Plug.Conn{} = conn) do
    sender = data.sender_request

    IO.inspect(tenant, label: "tenant from webhook")

    # IO.inspect(sender, label: "sender")

    # IO.inspect(rawdata, label: "rawdata")

    waba_id = Keyword.get(sender, :waba_id)
    sender_phone_number = Keyword.get(sender, :sender_phone_number)
    display_phone_number = Keyword.get(sender, :display_phone_number)
    phone_number_id = Keyword.get(sender, :phone_number_id)
    message = Keyword.get(sender, :message)
    wa_message_id = Keyword.get(sender, :wa_message_id)
    message_type = Keyword.get(sender, :message_type)
    image_caption = Keyword.get(sender, :image_caption)
    ref_whatsapp_id = Keyword.get(sender, :ref_whatsapp_id)
    # flow = Keyword.get(sender, :flow)
    # image_id = Keyword.get(sender, :image_id)
    # audio_id = Keyword.get(sender, :audio_id)
    # video_id = Keyword.get(sender, :video_id)
    # scheduled = Keyword.get(sender, :scheduled)
    # forwarded = Keyword.get(sender, :forwarded)
    #

    message =
      if is_nil(message),
        do: handle_multimedia(sender, message_type, display_phone_number, waba_id),
        else: message

    IO.inspect(phone_number_id, label: "webhook phone_number_id")

    chat_history_form = %{
      "message" => message,
      "phone_number_id" => phone_number_id,
      "sender_phone_number" => sender_phone_number,
      "whatsapp_id" => wa_message_id,
      "ref_whatsapp_id" => ref_whatsapp_id,
      "message_type" => message_type,
      "caption" => image_caption
    }

    chat_inbox = %{
      "sender_phone_number" => sender_phone_number,
      "phone_number_id" => phone_number_id,
      "readed" => false
    }

    ChatPubsub.subscribe(sender_phone_number, phone_number_id)

    IO.inspect(Flowmind.TenantContext.get_tenant(), label: "Flowmind.TenantContext.get_tenant()")
    Flowmind.TenantContext.put_tenant(tenant)
    IO.inspect(Flowmind.TenantContext.get_tenant(), label: "Flowmind.TenantContext.get_tenant()")

    Chat.create_chat_history(chat_history_form)
    |> ChatPubsub.notify(:message_created, sender_phone_number, phone_number_id)

    Chat.create_chat_inbox(chat_inbox) |> ChatPubsub.notify(:refresh_inbox, phone_number_id)

    log_notification(rawdata, waba_id)
  end

  def handle_notification(%Whatsapp.Meta.Request{} = data, rawdata, tenant, %Plug.Conn{} = _conn) do
    sender = data.meta_request
    waba_id = Keyword.get(sender, :waba_id)
    phone_number_id = Keyword.get(sender, :phone_number_id)
    sender_phone_number = Keyword.get(sender, :sender_phone_number)
    status = Keyword.get(sender, :status)

    IO.inspect(data.meta_request, label: "meta_request")

    Flowmind.TenantContext.put_tenant(tenant)

    case status do
      "read" ->
        whatsapp_id = Keyword.get(sender, :wa_message_id)

        ChatPubsub.subscribe(sender_phone_number, phone_number_id)

        Chat.mark_as_readed_or_delivered(whatsapp_id, :readed)
        |> ChatPubsub.notify(:notify_message_readed, sender_phone_number, phone_number_id)

      "delivered" ->
        whatsapp_id = Keyword.get(sender, :wa_message_id)

        ChatPubsub.subscribe(sender_phone_number, phone_number_id)

        Chat.mark_as_readed_or_delivered(whatsapp_id, :delivered)
        |> ChatPubsub.notify(:notify_message_delivered, sender_phone_number, phone_number_id)

      _ ->
        :ok
    end

    log_notification(rawdata, waba_id)
  end

  def handle_notification(_, _, _) do
    IO.puts("Nothing todo handle_notification !")
  end

  defp handle_multimedia(sender, message_type, display_phone_number, waba_id) do
    {message_type, message_type_id} =
      case message_type do
        "image" ->
          image_id = Keyword.get(sender, :image_id)
          {:image, image_id}

        "sticker" ->
          image_id = Keyword.get(sender, :sticker_id)
          {:sticker, image_id}

        "audio" ->
          audio_id = Keyword.get(sender, :audio_id)
          {:audio, audio_id}

        "video" ->
          video_id = Keyword.get(sender, :video_id)
          {:video, video_id}

        _ ->
          {:error, :not_found}
      end

    {_, filename} =
      MediaDl.get(
        message_type_id,
        display_phone_number,
        UUID.uuid1(),
        waba_id,
        :media,
        message_type
      )

    {_, filename} =
      if message_type == :audio do
        MediaDl.ogg_to_wav(filename)
      else
        {:ok, filename}
      end

    IO.inspect(filename, label: "filename_image")
    filename = filename |> String.split("flowmind") |> Enum.at(1)
    filename
  end

  def log_notification(data, waba_id) do
    Task.async(fn ->
      Process.sleep(5_000)

      log = %WebHookLog{
        source: @source_webhook,
        response: data,
        waba_id: waba_id
      }

      Webhook.Data.webhook_log(log)
    end)
  end
end
