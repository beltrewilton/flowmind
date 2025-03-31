defmodule Webhook.Router do
  use Plug.Router

  import Plug.Conn
  
  alias Flowmind.Chat
  alias FlowmindWeb.ChatPubsub

  plug(:match)
  plug(Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason)
  plug(:dispatch)

  # alias DBConnection.Task
  alias WhatsappElixir.Static, as: WS

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
    handle_notification(WS.handle_notification(data), data, tenant)

    send_resp(conn, 200, Jason.encode!(%{"status" => "success"}))
  end

  # forward("/flow", to: Flow.Router)

  match _ do
    send_resp(conn, 404, "You are trying something that does not exist.")
  end

  def handle_notification(%Whatsapp.Client.Sender{} = data, rawdata, tenant) do
    sender = data.sender_request
    
    IO.inspect(tenant, label: "tenant")
    
    IO.inspect(sender, label: "sender")
    
    IO.inspect(rawdata, label: "rawdata")
    
    waba_id = Keyword.get(sender, :waba_id)
    sender_phone_number = Keyword.get(sender, :sender_phone_number)
    display_phone_number = Keyword.get(sender, :display_phone_number)
    phone_number_id = Keyword.get(sender, :phone_number_id)
    message = Keyword.get(sender, :message)
    # wa_message_id = Keyword.get(sender, :wa_message_id)
    # flow = Keyword.get(sender, :flow)
    # audio_id = Keyword.get(sender, :audio_id)
    # video_id = Keyword.get(sender, :video_id)
    # scheduled = Keyword.get(sender, :scheduled)
    # forwarded = Keyword.get(sender, :forwarded)
    
    IO.inspect(phone_number_id, label: "webhook phone_number_id")
    
    chat_history_form = %{"message" => message, "phone_number_id" => phone_number_id, "sender_phone_number" => sender_phone_number}
    
    chat_inbox = %{"sender_phone_number" => sender_phone_number, "phone_number_id" => phone_number_id, "readed" => false}
    
    ChatPubsub.subscribe(sender_phone_number)
    
    Chat.create_chat_history(chat_history_form) |> ChatPubsub.notify(:message_created, sender_phone_number)
    
    Chat.create_chat_inbox(chat_inbox) |> ChatPubsub.notify(:refresh_inbox, display_phone_number)
      
    log_notification(rawdata, waba_id)

  end

  def handle_notification(%Whatsapp.Meta.Request{} = data, rawdata, tenant) do
    sender = data.meta_request
    waba_id = Keyword.get(sender, :waba_id)

    log_notification(rawdata, waba_id)

    IO.puts("No redirect for this content .. !")
    IO.inspect(data)
  end

  def handle_notification(_, _) do
    IO.puts("Nothing todo handle_notification !")
  end

  def log_notification(data, waba_id) do
    Task.async(
      fn ->
        Process.sleep(5_000)
        log = %WebHookLog{
          source: @source_webhook,
          response: data,
          waba_id: waba_id
        }
        Webhook.Data.webhook_log(log)
      end
    )
  end
end