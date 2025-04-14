defmodule FlowmindWeb.Presence do
  use Phoenix.Presence,
    otp_app: :flowmind,
    pubsub_server: Flowmind.PubSub
end
