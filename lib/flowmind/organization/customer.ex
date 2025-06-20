defmodule Flowmind.Organization.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "customers" do
    field :name, :string
    field :status, Ecto.Enum, values: [:active, :inactive], default: :active
    field :phone_number, :string
    field :email, :string
    field :avatar, :string
    field :document_id, :string
    field :country, :string
    field :note, :string
    field :checked, :boolean, virtual: true, default: false
    field :extra_fields, :map

    # belongs_to :user, Flowmind.Accounts.User
    many_to_many :users, Flowmind.Accounts.User,
      join_through: "users_customers",
      join_keys: [customer_id: :id, user_id: :id],
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [
      :phone_number,
      :name,
      :email,
      :avatar,
      :status,
      :document_id,
      :country,
      :note,
      :extra_fields
    ])
    |> validate_required([:phone_number])
  end
end
