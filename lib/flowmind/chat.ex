defmodule Flowmind.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias Flowmind.Repo

  alias Flowmind.Chat.ChatHistory
  alias Flowmind.Organization
  alias Flowmind.Accounts
  alias Flowmind.Accounts.User

  @doc """
  Returns the list of chat_history.

  ## Examples

      iex> list_chat_history()
      [%ChatHistory{}, ...]

  """
  def list_chat_history do
    tenant = Flowmind.TenantContext.get_tenant()
    Repo.all(ChatHistory, prefix: tenant)
  end

  def list_chat_history(sender_phone_number) do
    tenant = Flowmind.TenantContext.get_tenant()

    chat_history =
      from ch in ChatHistory,
        where: ch.sender_phone_number == ^sender_phone_number,
        order_by: [asc: ch.inserted_at]

    case Repo.all(chat_history, prefix: tenant) do
      [] -> []
      chat_histories -> chat_histories |> Repo.preload([:chat_history])
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
    tenant = Flowmind.TenantContext.get_tenant()
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
    tenant = Flowmind.TenantContext.get_tenant()

    changeset =
      %ChatHistory{}
      |> ChatHistory.changeset(attrs)

    with {:ok, entity} <- Repo.insert(changeset, prefix: tenant) do
      {:ok, Repo.preload(entity, [:chat_history])}
    end
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
    tenant = Flowmind.TenantContext.get_tenant()

    chat_history
    |> ChatHistory.changeset(attrs)
    |> Repo.update(prefix: tenant)
  end

  def mark_as_readed_or_delivered(whatsapp_id, action \\ :delivered) do
    tenant = Flowmind.TenantContext.get_tenant()

    query =
      from(ch in ChatHistory,
        where: ch.whatsapp_id == ^whatsapp_id
      )

    if action == :delivered do
      Repo.update_all(
        query,
        [set: [delivered: true]],
        prefix: tenant
      )
    else
      Repo.update_all(
        query,
        [set: [readed: true]],
        prefix: tenant
      )
    end

    {:ok,
     Repo.get_by(ChatHistory, [whatsapp_id: whatsapp_id], prefix: tenant)
     |> Repo.preload([:chat_history])}
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
    tenant = Flowmind.TenantContext.get_tenant()
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
    tenant = Flowmind.TenantContext.get_tenant()

    ChatInbox
    |> order_by(desc: :updated_at)
    |> Repo.all(prefix: tenant)
  end
  
  
  def list_chat_inbox(%User{} = user) do
    tenant = Flowmind.TenantContext.get_tenant()
    
    user = Flowmind.Repo.preload(user, :customers, prefix: tenant)
    
    IO.inspect(user, label: "user")

    phone_numbers =
      user.customers
      |> Enum.map(& &1.phone_number)
      |> Enum.reject(&is_nil/1)

    ChatInbox
    |> where([ci], ci.sender_phone_number in ^phone_numbers)
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
    tenant = Flowmind.TenantContext.get_tenant()
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
    tenant = Flowmind.TenantContext.get_tenant()

    case Repo.get_by(ChatInbox, [sender_phone_number: attrs["sender_phone_number"]],
           prefix: tenant
         ) do
      nil ->
        attrs = Map.put(attrs, "seed", UUID.uuid1())

        {_, customer} = Organization.create_customer(%{phone_number: attrs["sender_phone_number"]})
        
        user = Accounts.get_users_by_tenant(tenant)
        Accounts.update_user_customers(user, [customer])

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
    tenant = Flowmind.TenantContext.get_tenant()
    
    IO.inspect(tenant, label: "update_chat_inbox:tenant")

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
    tenant = Flowmind.TenantContext.get_tenant()
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
