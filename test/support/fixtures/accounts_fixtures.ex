defmodule Flowmind.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Flowmind.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Flowmind.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  @doc """
  Generate a unique company tenant.
  """
  def unique_company_tenant, do: "some tenant#{System.unique_integer([:positive])}"

  @doc """
  Generate a company.
  """
  def company_fixture(attrs \\ %{}) do
    {:ok, company} =
      attrs
      |> Enum.into(%{
        name: "some name",
        tenant: unique_company_tenant()
      })
      |> Flowmind.Accounts.create_company()

    company
  end

  @doc """
  Generate a tenant_account.
  """
  def tenant_account_fixture(attrs \\ %{}) do
    {:ok, tenant_account} =
      attrs
      |> Enum.into(%{
        access_token: "some access_token",
        active: true,
        phone_number_id: "some phone_number_id",
        register_ph_response: %{},
        subscribed_apps_response: %{},
        token_exchange_code: "some token_exchange_code",
        waba_id: "some waba_id"
      })
      |> Flowmind.Accounts.create_tenant_account()

    tenant_account
  end
end
