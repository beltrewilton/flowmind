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
end
