defmodule Flowmind.OrganizationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Flowmind.Organization` context.
  """

  @doc """
  Generate a employee.
  """
  def employee_fixture(attrs \\ %{}) do
    {:ok, employee} =
      attrs
      |> Enum.into(%{
        department: "some department",
        job_title: "some job_title",
        status: "some status"
      })
      |> Flowmind.Organization.create_employee()

    employee
  end

  @doc """
  Generate a customer.
  """
  def customer_fixture(attrs \\ %{}) do
    {:ok, customer} =
      attrs
      |> Enum.into(%{
        avatar: "some avatar",
        document_id: "some document_id",
        email: "some email",
        name: "some name",
        note: "some note",
        phone_number: "some phone_number",
        status: "some status"
      })
      |> Flowmind.Organization.create_customer()

    customer
  end
end
