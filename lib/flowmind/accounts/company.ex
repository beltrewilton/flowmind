defmodule Flowmind.Accounts.Company do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "company" do
    field :company_name, :string
    field :tenant, :string
    field :phone_number_id, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(company, attrs) do
    company
    |> cast(attrs, [
      :company_name,
      :tenant,
      :phone_number_id
    ])
    |> validate_required([
      :company_name,
      :tenant
    ])
    |> validate_length(:company_name, min: 4, max: 30)
    |> validate_format(:tenant, ~r/^[a-z]+$/, message: "must contain only lowercase letters")
    |> validate_length(:tenant, min: 4, max: 10)
    |> unique_constraint(:tenant)
  end
end
