defmodule Webhook.Data do
  import Ecto.Query, warn: false
  alias Flowmind.Repo

  def webhook_log(log \\ %WebHookLog{}) do
    changeset = %WebHookLogSchema{} |> WebHookLogSchema.changeset(Map.from_struct(log))

    case Repo.insert(changeset) do
      {:ok, record} -> {:ok, record}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def cta_log(log \\ %CTALog{}) do
    changeset = %CTALogSchema{} |> CTALogSchema.changeset(Map.from_struct(log))

    case Repo.insert(changeset) do
      {:ok, record} -> {:ok, record}
      {:error, changeset} -> {:error, changeset}
    end
  end
end
