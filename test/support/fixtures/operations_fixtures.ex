defmodule Flowmind.OperationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Flowmind.Operations` context.
  """

  @doc """
  Generate a tenant_account.
  """
  def tenant_account_fixture(attrs \\ %{}) do
    {:ok, tenant_account} =
      attrs
      |> Enum.into(%{
        config: "some config",
        waba: "some waba"
      })
      |> Flowmind.Operations.create_tenant_account()

    tenant_account
  end
end
