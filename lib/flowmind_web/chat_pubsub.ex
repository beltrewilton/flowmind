defmodule FlowmindWeb.ChatPubsub do
  alias Phoenix.PubSub
  
  defp prefix_mask(phone_number, prefix) when is_nil(prefix),  do: phone_number
  
  defp prefix_mask(phone_number, prefix),  do: "#{prefix}:#{phone_number}"

  def subscribe(sender_phone_number, prefix \\ nil) do
    PubSub.subscribe(Flowmind.PubSub, prefix_mask(sender_phone_number, prefix))
  end
  
  def unsubscribe(old_sender_phone_number, prefix \\ nil) do
    PubSub.unsubscribe(Flowmind.PubSub, prefix_mask(old_sender_phone_number, prefix))
  end

  def notify(message, event, sender_phone_number, prefix \\ nil) do
    PubSub.broadcast(Flowmind.PubSub, prefix_mask(sender_phone_number, prefix), {event, message})
  end

  def notify({:error, reason}, _event), do: {:error, reason}
end
