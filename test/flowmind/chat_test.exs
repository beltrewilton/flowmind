defmodule Flowmind.ChatTest do
  use Flowmind.DataCase

  alias Flowmind.Chat

  describe "chat_history" do
    alias Flowmind.Chat.ChatHistory

    import Flowmind.ChatFixtures

    @invalid_attrs %{
      message: nil,
      phone_number_id: nil,
      whatsapp_id: nil,
      readed: nil,
      collected: nil
    }

    test "list_chat_history/0 returns all chat_history" do
      chat_history = chat_history_fixture()
      assert Chat.list_chat_history() == [chat_history]
    end

    test "get_chat_history!/1 returns the chat_history with given id" do
      chat_history = chat_history_fixture()
      assert Chat.get_chat_history!(chat_history.id) == chat_history
    end

    test "create_chat_history/1 with valid data creates a chat_history" do
      valid_attrs = %{
        message: "some message",
        phone_number_id: "some phone_number_id",
        whatsapp_id: "some whatsapp_id",
        readed: true,
        collected: true
      }

      assert {:ok, %ChatHistory{} = chat_history} = Chat.create_chat_history(valid_attrs)
      assert chat_history.message == "some message"
      assert chat_history.phone_number_id == "some phone_number_id"
      assert chat_history.whatsapp_id == "some whatsapp_id"
      assert chat_history.readed == true
      assert chat_history.collected == true
    end

    test "create_chat_history/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Chat.create_chat_history(@invalid_attrs)
    end

    test "update_chat_history/2 with valid data updates the chat_history" do
      chat_history = chat_history_fixture()

      update_attrs = %{
        message: "some updated message",
        phone_number_id: "some updated phone_number_id",
        whatsapp_id: "some updated whatsapp_id",
        readed: false,
        collected: false
      }

      assert {:ok, %ChatHistory{} = chat_history} =
               Chat.update_chat_history(chat_history, update_attrs)

      assert chat_history.message == "some updated message"
      assert chat_history.phone_number_id == "some updated phone_number_id"
      assert chat_history.whatsapp_id == "some updated whatsapp_id"
      assert chat_history.readed == false
      assert chat_history.collected == false
    end

    test "update_chat_history/2 with invalid data returns error changeset" do
      chat_history = chat_history_fixture()
      assert {:error, %Ecto.Changeset{}} = Chat.update_chat_history(chat_history, @invalid_attrs)
      assert chat_history == Chat.get_chat_history!(chat_history.id)
    end

    test "delete_chat_history/1 deletes the chat_history" do
      chat_history = chat_history_fixture()
      assert {:ok, %ChatHistory{}} = Chat.delete_chat_history(chat_history)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_chat_history!(chat_history.id) end
    end

    test "change_chat_history/1 returns a chat_history changeset" do
      chat_history = chat_history_fixture()
      assert %Ecto.Changeset{} = Chat.change_chat_history(chat_history)
    end
  end

  describe "chat_inbox" do
    alias Flowmind.Chat.ChatInbox

    import Flowmind.ChatFixtures

    @invalid_attrs %{phone_number_id: nil, sender_phone_number: nil}

    test "list_chat_inbox/0 returns all chat_inbox" do
      chat_inbox = chat_inbox_fixture()
      assert Chat.list_chat_inbox() == [chat_inbox]
    end

    test "get_chat_inbox!/1 returns the chat_inbox with given id" do
      chat_inbox = chat_inbox_fixture()
      assert Chat.get_chat_inbox!(chat_inbox.id) == chat_inbox
    end

    test "create_chat_inbox/1 with valid data creates a chat_inbox" do
      valid_attrs = %{
        phone_number_id: "some phone_number_id",
        sender_phone_number: "some sender_phone_number"
      }

      assert {:ok, %ChatInbox{} = chat_inbox} = Chat.create_chat_inbox(valid_attrs)
      assert chat_inbox.phone_number_id == "some phone_number_id"
      assert chat_inbox.sender_phone_number == "some sender_phone_number"
    end

    test "create_chat_inbox/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Chat.create_chat_inbox(@invalid_attrs)
    end

    test "update_chat_inbox/2 with valid data updates the chat_inbox" do
      chat_inbox = chat_inbox_fixture()

      update_attrs = %{
        phone_number_id: "some updated phone_number_id",
        sender_phone_number: "some updated sender_phone_number"
      }

      assert {:ok, %ChatInbox{} = chat_inbox} = Chat.update_chat_inbox(chat_inbox, update_attrs)
      assert chat_inbox.phone_number_id == "some updated phone_number_id"
      assert chat_inbox.sender_phone_number == "some updated sender_phone_number"
    end

    test "update_chat_inbox/2 with invalid data returns error changeset" do
      chat_inbox = chat_inbox_fixture()
      assert {:error, %Ecto.Changeset{}} = Chat.update_chat_inbox(chat_inbox, @invalid_attrs)
      assert chat_inbox == Chat.get_chat_inbox!(chat_inbox.id)
    end

    test "delete_chat_inbox/1 deletes the chat_inbox" do
      chat_inbox = chat_inbox_fixture()
      assert {:ok, %ChatInbox{}} = Chat.delete_chat_inbox(chat_inbox)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_chat_inbox!(chat_inbox.id) end
    end

    test "change_chat_inbox/1 returns a chat_inbox changeset" do
      chat_inbox = chat_inbox_fixture()
      assert %Ecto.Changeset{} = Chat.change_chat_inbox(chat_inbox)
    end
  end
end
