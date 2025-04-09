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
end
