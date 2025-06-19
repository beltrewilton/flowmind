defmodule Flowmind.OperationsTest do
  use Flowmind.DataCase

  alias Flowmind.Operations

  describe "tenant_account" do
    alias Flowmind.Operations.TenantAccount

    import Flowmind.OperationsFixtures

    @invalid_attrs %{config: nil, waba: nil}

    test "list_tenant_account/0 returns all tenant_account" do
      tenant_account = tenant_account_fixture()
      assert Operations.list_tenant_account() == [tenant_account]
    end

    test "get_tenant_account!/1 returns the tenant_account with given id" do
      tenant_account = tenant_account_fixture()
      assert Operations.get_tenant_account!(tenant_account.id) == tenant_account
    end

    test "create_tenant_account/1 with valid data creates a tenant_account" do
      valid_attrs = %{config: "some config", waba: "some waba"}

      assert {:ok, %TenantAccount{} = tenant_account} =
               Operations.create_tenant_account(valid_attrs)

      assert tenant_account.config == "some config"
      assert tenant_account.waba == "some waba"
    end

    test "create_tenant_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Operations.create_tenant_account(@invalid_attrs)
    end

    test "update_tenant_account/2 with valid data updates the tenant_account" do
      tenant_account = tenant_account_fixture()
      update_attrs = %{config: "some updated config", waba: "some updated waba"}

      assert {:ok, %TenantAccount{} = tenant_account} =
               Operations.update_tenant_account(tenant_account, update_attrs)

      assert tenant_account.config == "some updated config"
      assert tenant_account.waba == "some updated waba"
    end

    test "update_tenant_account/2 with invalid data returns error changeset" do
      tenant_account = tenant_account_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Operations.update_tenant_account(tenant_account, @invalid_attrs)

      assert tenant_account == Operations.get_tenant_account!(tenant_account.id)
    end

    test "delete_tenant_account/1 deletes the tenant_account" do
      tenant_account = tenant_account_fixture()
      assert {:ok, %TenantAccount{}} = Operations.delete_tenant_account(tenant_account)

      assert_raise Ecto.NoResultsError, fn ->
        Operations.get_tenant_account!(tenant_account.id)
      end
    end

    test "change_tenant_account/1 returns a tenant_account changeset" do
      tenant_account = tenant_account_fixture()
      assert %Ecto.Changeset{} = Operations.change_tenant_account(tenant_account)
    end
  end
end
