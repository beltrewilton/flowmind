defmodule Flowmind.Organization do
  @moduledoc """
  The Organization context.
  """

  import Ecto.Query, warn: false
  alias Flowmind.Repo

  alias Flowmind.Organization.Employee

  @doc """
  Returns the list of employees.

  ## Examples

      iex> list_employees()
      [%Employee{}, ...]

  """
  def list_employees do
    tenant = Flowmind.TenantGenServer.get_tenant()
    Repo.all(Employee, prefix: tenant)
  end

  @doc """
  Gets a single employee.

  Raises `Ecto.NoResultsError` if the Employee does not exist.

  ## Examples

      iex> get_employee!(123)
      %Employee{}

      iex> get_employee!(456)
      ** (Ecto.NoResultsError)

  """
  def get_employee!(id) do
    tenant = Flowmind.TenantGenServer.get_tenant()
    Repo.get!(Employee, id, prefix: tenant)
  end

  @doc """
  Creates a employee.

  ## Examples

      iex> create_employee(%{field: value})
      {:ok, %Employee{}}

      iex> create_employee(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_employee(attrs \\ %{}) do
    tenant = Flowmind.TenantGenServer.get_tenant()
    %Employee{}
    |> Employee.changeset(attrs)
    |> Repo.insert(prefix: tenant)
  end

  @doc """
  Updates a employee.

  ## Examples

      iex> update_employee(employee, %{field: new_value})
      {:ok, %Employee{}}

      iex> update_employee(employee, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_employee(%Employee{} = employee, attrs) do
    tenant = Flowmind.TenantGenServer.get_tenant()
    employee
    |> Employee.changeset(attrs)
    |> Repo.update(prefix: tenant)
  end

  @doc """
  Deletes a employee.

  ## Examples

      iex> delete_employee(employee)
      {:ok, %Employee{}}

      iex> delete_employee(employee)
      {:error, %Ecto.Changeset{}}

  """
  def delete_employee(%Employee{} = employee) do
    tenant = Flowmind.TenantGenServer.get_tenant()
    Repo.delete(employee, prefix: tenant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking employee changes.

  ## Examples

      iex> change_employee(employee)
      %Ecto.Changeset{data: %Employee{}}

  """
  def change_employee(%Employee{} = employee, attrs \\ %{}) do
    Employee.changeset(employee, attrs)
  end

  alias Flowmind.Organization.Customer

  @doc """
  Returns the list of customers.

  ## Examples

      iex> list_customers()
      [%Customer{}, ...]

  """
  def list_customers do
    tenant = Flowmind.TenantGenServer.get_tenant()
    Repo.all(Customer, prefix: tenant)
  end

  @doc """
  Gets a single customer.

  Raises `Ecto.NoResultsError` if the Customer does not exist.

  ## Examples

      iex> get_customer!(123)
      %Customer{}

      iex> get_customer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_customer!(id) do 
    tenant = Flowmind.TenantGenServer.get_tenant()
    Repo.get!(Customer, id, prefix: tenant)
  end

  @doc """
  Creates a customer.

  ## Examples

      iex> create_customer(%{field: value})
      {:ok, %Customer{}}

      iex> create_customer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_customer(attrs \\ %{}) do
    tenant = Flowmind.TenantGenServer.get_tenant()
    %Customer{}
    |> Customer.changeset(attrs)
    |> Repo.insert(prefix: tenant)
  end

  @doc """
  Updates a customer.

  ## Examples

      iex> update_customer(customer, %{field: new_value})
      {:ok, %Customer{}}

      iex> update_customer(customer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_customer(%Customer{} = customer, attrs) do
    tenant = Flowmind.TenantGenServer.get_tenant()
    customer
    |> Customer.changeset(attrs)
    |> Repo.update(prefix: tenant)
  end

  @doc """
  Deletes a customer.

  ## Examples

      iex> delete_customer(customer)
      {:ok, %Customer{}}

      iex> delete_customer(customer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_customer(%Customer{} = customer) do
    tenant = Flowmind.TenantGenServer.get_tenant()
    Repo.delete(customer, prefix: tenant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking customer changes.

  ## Examples

      iex> change_customer(customer)
      %Ecto.Changeset{data: %Customer{}}

  """
  def change_customer(%Customer{} = customer, attrs \\ %{}) do
    Customer.changeset(customer, attrs)
  end
end
