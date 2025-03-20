defmodule Flowmind.Operations do
  @moduledoc """
  The Operations context.
  """

  import Ecto.Query, warn: false
  alias Flowmind.Repo

  alias Flowmind.Operations.TenantAccount

  @doc """
  Returns the list of tenant_account.

  ## Examples

      iex> list_tenant_account()
      [%TenantAccount{}, ...]

  """
  def list_tenant_account() do
    tenant = Flowmind.TenantGenServer.get_tenant()
    IO.inspect(tenant, label: "tenant -> ")
    Repo.all(TenantAccount, prefix: Triplex.to_prefix(tenant))
  end

  @doc """
  Gets a single tenant_account.

  Raises `Ecto.NoResultsError` if the Tenant account does not exist.

  ## Examples

      iex> get_tenant_account!(123)
      %TenantAccount{}

      iex> get_tenant_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tenant_account!(id), do: Repo.get!(TenantAccount, id)

  @doc """
  Creates a tenant_account.

  ## Examples

      iex> create_tenant_account(%{field: value})
      {:ok, %TenantAccount{}}

      iex> create_tenant_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tenant_account(attrs \\ %{}) do
    %TenantAccount{}
    |> TenantAccount.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tenant_account.

  ## Examples

      iex> update_tenant_account(tenant_account, %{field: new_value})
      {:ok, %TenantAccount{}}

      iex> update_tenant_account(tenant_account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tenant_account(%TenantAccount{} = tenant_account, attrs) do
    tenant_account
    |> TenantAccount.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tenant_account.

  ## Examples

      iex> delete_tenant_account(tenant_account)
      {:ok, %TenantAccount{}}

      iex> delete_tenant_account(tenant_account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tenant_account(%TenantAccount{} = tenant_account) do
    Repo.delete(tenant_account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tenant_account changes.

  ## Examples

      iex> change_tenant_account(tenant_account)
      %Ecto.Changeset{data: %TenantAccount{}}

  """
  def change_tenant_account(%TenantAccount{} = tenant_account, attrs \\ %{}) do
    TenantAccount.changeset(tenant_account, attrs)
  end
end
