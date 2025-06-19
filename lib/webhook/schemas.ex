defmodule WebHookLogSchema do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "webhook_log" do
    field(:source, :string)
    field(:response, :map)
    field(:waba_id, :string)

    timestamps(type: :utc_datetime)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :source,
      :response,
      :waba_id
    ])
    |> validate_required([
      :source
    ])
  end
end

defmodule CTALogSchema do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "cta_log" do
    field(:referer, :string)
    field(:user_agent, :string)
    field(:campaign, :string)
    field(:waba_id, :string)

    timestamps(type: :utc_datetime)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :referer,
      :user_agent,
      :campaign,
      :waba_id
    ])
    |> validate_required([
      :referer,
      :user_agent,
      :campaign
    ])
  end
end
