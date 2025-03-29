defmodule Flowmind.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias Flowmind.Repo

  alias Flowmind.Chat.ChatHistory

  @doc """
  Returns the list of chat_history.

  ## Examples

      iex> list_chat_history()
      [%ChatHistory{}, ...]

  """
  def list_chat_history do
    tenant = Flowmind.TenantGenServer.get_tenant()
    Repo.all(ChatHistory, prefix: tenant)
  end

  def list_chat_history(sender_phone_number) do
    tenant = Flowmind.TenantGenServer.get_tenant()

    chat_history =
      from ch in ChatHistory,
        where: ch.sender_phone_number == ^sender_phone_number,
        order_by: [asc: ch.inserted_at]

    case Repo.all(chat_history, prefix: tenant) do
      [] -> []
      chat_histories -> chat_histories
    end
  end

  @doc """
  Gets a single chat_history.

  Raises `Ecto.NoResultsError` if the Chat history does not exist.

  ## Examples

      iex> get_chat_history!(123)
      %ChatHistory{}

      iex> get_chat_history!(456)
      ** (Ecto.NoResultsError)

  """
  def get_chat_history!(id) do
    tenant = Flowmind.TenantGenServer.get_tenant()
    Repo.get!(ChatHistory, id, prefix: tenant)
  end

  @doc """
  Creates a chat_history.

  ## Examples

      iex> create_chat_history(%{field: value})
      {:ok, %ChatHistory{}}

      iex> create_chat_history(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_chat_history(attrs \\ %{}) do
    tenant = Flowmind.TenantGenServer.get_tenant()

    %ChatHistory{}
    |> ChatHistory.changeset(attrs)
    |> Repo.insert(prefix: tenant)
  end

  @doc """
  Updates a chat_history.

  ## Examples

      iex> update_chat_history(chat_history, %{field: new_value})
      {:ok, %ChatHistory{}}

      iex> update_chat_history(chat_history, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_chat_history(%ChatHistory{} = chat_history, attrs) do
    tenant = Flowmind.TenantGenServer.get_tenant()

    chat_history
    |> ChatHistory.changeset(attrs)
    |> Repo.update(prefix: tenant)
  end

  @doc """
  Deletes a chat_history.

  ## Examples

      iex> delete_chat_history(chat_history)
      {:ok, %ChatHistory{}}

      iex> delete_chat_history(chat_history)
      {:error, %Ecto.Changeset{}}

  """
  def delete_chat_history(%ChatHistory{} = chat_history) do
    tenant = Flowmind.TenantGenServer.get_tenant()
    Repo.delete(chat_history, prefix: tenant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chat_history changes.

  ## Examples

      iex> change_chat_history(chat_history)
      %Ecto.Changeset{data: %ChatHistory{}}

  """
  def change_chat_history(%ChatHistory{} = chat_history, attrs \\ %{}) do
    ChatHistory.changeset(chat_history, attrs)
  end

  alias Flowmind.Chat.ChatInbox

  @doc """
  Returns the list of chat_inbox.

  ## Examples

      iex> list_chat_inbox()
      [%ChatInbox{}, ...]

  """
  def list_chat_inbox do
    tenant = Flowmind.TenantGenServer.get_tenant()

    ChatInbox
    |> order_by(desc: :updated_at)
    |> Repo.all(prefix: tenant)
  end

  @doc """
  Gets a single chat_inbox.

  Raises `Ecto.NoResultsError` if the Chat inbox does not exist.

  ## Examples

      iex> get_chat_inbox!(123)
      %ChatInbox{}

      iex> get_chat_inbox!(456)
      ** (Ecto.NoResultsError)

  """
  def get_chat_inbox!(id) do
    tenant = Flowmind.TenantGenServer.get_tenant()
    Repo.get!(ChatInbox, id, prefix: tenant)
  end

  @doc """
  Creates a chat_inbox.

  ## Examples

      iex> create_chat_inbox(%{field: value})
      {:ok, %ChatInbox{}}

      iex> create_chat_inbox(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_chat_inbox(attrs \\ %{}) do
    tenant = Flowmind.TenantGenServer.get_tenant()

    case Repo.get_by(ChatInbox, [sender_phone_number: attrs["sender_phone_number"]],
           prefix: tenant
         ) do
      nil ->
        attrs = Map.put(attrs, "seed", UUID.uuid1())

        %ChatInbox{}
        |> ChatInbox.changeset(attrs)
        |> Repo.insert(prefix: tenant)

      chat_inbox ->
        attrs = Map.put(attrs, "seed", UUID.uuid1())

        chat_inbox
        |> ChatInbox.changeset(attrs)
        |> Repo.update(prefix: tenant)
    end
  end

  @doc """
  Updates a chat_inbox.

  ## Examples

      iex> update_chat_inbox(chat_inbox, %{field: new_value})
      {:ok, %ChatInbox{}}

      iex> update_chat_inbox(chat_inbox, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_chat_inbox(%ChatInbox{} = chat_inbox, attrs) do
    tenant = Flowmind.TenantGenServer.get_tenant()

    chat_inbox
    |> ChatInbox.changeset(attrs)
    |> Repo.update(prefix: tenant)
  end

  @doc """
  Deletes a chat_inbox.

  ## Examples

      iex> delete_chat_inbox(chat_inbox)
      {:ok, %ChatInbox{}}

      iex> delete_chat_inbox(chat_inbox)
      {:error, %Ecto.Changeset{}}

  """
  def delete_chat_inbox(%ChatInbox{} = chat_inbox) do
    tenant = Flowmind.TenantGenServer.get_tenant()
    Repo.delete(chat_inbox, prefix: tenant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chat_inbox changes.

  ## Examples

      iex> change_chat_inbox(chat_inbox)
      %Ecto.Changeset{data: %ChatInbox{}}

  """
  def change_chat_inbox(%ChatInbox{} = chat_inbox, attrs \\ %{}) do
    ChatInbox.changeset(chat_inbox, attrs)
  end
end
