defmodule Flowmind.OrganizationTest do
  use Flowmind.DataCase

  alias Flowmind.Organization

  describe "employees" do
    alias Flowmind.Organization.Employee

    import Flowmind.OrganizationFixtures

    @invalid_attrs %{status: nil, job_title: nil, department: nil}

    test "list_employees/0 returns all employees" do
      employee = employee_fixture()
      assert Organization.list_employees() == [employee]
    end

    test "get_employee!/1 returns the employee with given id" do
      employee = employee_fixture()
      assert Organization.get_employee!(employee.id) == employee
    end

    test "create_employee/1 with valid data creates a employee" do
      valid_attrs = %{status: "some status", job_title: "some job_title", department: "some department"}

      assert {:ok, %Employee{} = employee} = Organization.create_employee(valid_attrs)
      assert employee.status == "some status"
      assert employee.job_title == "some job_title"
      assert employee.department == "some department"
    end

    test "create_employee/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Organization.create_employee(@invalid_attrs)
    end

    test "update_employee/2 with valid data updates the employee" do
      employee = employee_fixture()
      update_attrs = %{status: "some updated status", job_title: "some updated job_title", department: "some updated department"}

      assert {:ok, %Employee{} = employee} = Organization.update_employee(employee, update_attrs)
      assert employee.status == "some updated status"
      assert employee.job_title == "some updated job_title"
      assert employee.department == "some updated department"
    end

    test "update_employee/2 with invalid data returns error changeset" do
      employee = employee_fixture()
      assert {:error, %Ecto.Changeset{}} = Organization.update_employee(employee, @invalid_attrs)
      assert employee == Organization.get_employee!(employee.id)
    end

    test "delete_employee/1 deletes the employee" do
      employee = employee_fixture()
      assert {:ok, %Employee{}} = Organization.delete_employee(employee)
      assert_raise Ecto.NoResultsError, fn -> Organization.get_employee!(employee.id) end
    end

    test "change_employee/1 returns a employee changeset" do
      employee = employee_fixture()
      assert %Ecto.Changeset{} = Organization.change_employee(employee)
    end
  end
end
