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

  describe "customers" do
    alias Flowmind.Organization.Customer

    import Flowmind.OrganizationFixtures

    @invalid_attrs %{name: nil, status: nil, phone_number: nil, email: nil, avatar: nil, document_id: nil, note: nil}

    test "list_customers/0 returns all customers" do
      customer = customer_fixture()
      assert Organization.list_customers() == [customer]
    end

    test "get_customer!/1 returns the customer with given id" do
      customer = customer_fixture()
      assert Organization.get_customer!(customer.id) == customer
    end

    test "create_customer/1 with valid data creates a customer" do
      valid_attrs = %{name: "some name", status: "some status", phone_number: "some phone_number", email: "some email", avatar: "some avatar", document_id: "some document_id", note: "some note"}

      assert {:ok, %Customer{} = customer} = Organization.create_customer(valid_attrs)
      assert customer.name == "some name"
      assert customer.status == "some status"
      assert customer.phone_number == "some phone_number"
      assert customer.email == "some email"
      assert customer.avatar == "some avatar"
      assert customer.document_id == "some document_id"
      assert customer.note == "some note"
    end

    test "create_customer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Organization.create_customer(@invalid_attrs)
    end

    test "update_customer/2 with valid data updates the customer" do
      customer = customer_fixture()
      update_attrs = %{name: "some updated name", status: "some updated status", phone_number: "some updated phone_number", email: "some updated email", avatar: "some updated avatar", document_id: "some updated document_id", note: "some updated note"}

      assert {:ok, %Customer{} = customer} = Organization.update_customer(customer, update_attrs)
      assert customer.name == "some updated name"
      assert customer.status == "some updated status"
      assert customer.phone_number == "some updated phone_number"
      assert customer.email == "some updated email"
      assert customer.avatar == "some updated avatar"
      assert customer.document_id == "some updated document_id"
      assert customer.note == "some updated note"
    end

    test "update_customer/2 with invalid data returns error changeset" do
      customer = customer_fixture()
      assert {:error, %Ecto.Changeset{}} = Organization.update_customer(customer, @invalid_attrs)
      assert customer == Organization.get_customer!(customer.id)
    end

    test "delete_customer/1 deletes the customer" do
      customer = customer_fixture()
      assert {:ok, %Customer{}} = Organization.delete_customer(customer)
      assert_raise Ecto.NoResultsError, fn -> Organization.get_customer!(customer.id) end
    end

    test "change_customer/1 returns a customer changeset" do
      customer = customer_fixture()
      assert %Ecto.Changeset{} = Organization.change_customer(customer)
    end
  end
end
