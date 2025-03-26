defmodule FlowmindWeb.ChatPubsub do
  alias Phoenix.PubSub

  def subscribe(sender_phone_number) do
    PubSub.subscribe(Flowmind.PubSub, sender_phone_number)
  end
  
  def unsubscribe(old_sender_phone_number) do
    PubSub.unsubscribe(Flowmind.PubSub, old_sender_phone_number)
  end

  def notify({:ok, message}, event, sender_phone_number) do
    PubSub.broadcast(Flowmind.PubSub, sender_phone_number, {event, message})
  end

  def notify({:error, reason}, _event), do: {:error, reason}
end
