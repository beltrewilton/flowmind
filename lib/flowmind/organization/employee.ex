defmodule Flowmind.Organization.Employee do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "employees" do
    field :status, Ecto.Enum, values: [:active, :inactive], default: :active
    field :job_title, :string
    field :department, :string

    belongs_to :user, Flowmind.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(employee, attrs) do
    employee
    |> cast(attrs, [:job_title, :department, :status, :user_id])
    |> validate_required([:job_title, :department, :status])
  end
end
