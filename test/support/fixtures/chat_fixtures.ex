defmodule Flowmind.ChatFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Flowmind.Chat` context.
  """

  @doc """
  Generate a chat_history.
  """
  def chat_history_fixture(attrs \\ %{}) do
    {:ok, chat_history} =
      attrs
      |> Enum.into(%{
        collected: true,
        message: "some message",
        phone_number_id: "some phone_number_id",
        readed: true,
        whatsapp_id: "some whatsapp_id"
      })
      |> Flowmind.Chat.create_chat_history()

    chat_history
  end
end
