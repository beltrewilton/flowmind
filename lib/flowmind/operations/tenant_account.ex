defmodule Flowmind.Operations.TenantAccount do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tenant_account" do
    field :config, :string
    field :waba, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tenant_account, attrs) do
    tenant_account
    |> cast(attrs, [:waba, :config])
    |> validate_required([:waba, :config])
  end
end
