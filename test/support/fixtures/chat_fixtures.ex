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

  @doc """
  Generate a chat_inbox.
  """
  def chat_inbox_fixture(attrs \\ %{}) do
    {:ok, chat_inbox} =
      attrs
      |> Enum.into(%{
        phone_number_id: "some phone_number_id",
        sender_phone_number: "some sender_phone_number"
      })
      |> Flowmind.Chat.create_chat_inbox()

    chat_inbox
  end
end
