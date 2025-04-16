defmodule Flowmind.Data.Mem do
  alias Hex.API.User
  alias :mnesia, as: Mnesia

  @tenant_transact_fields [:phone_number_id, :tenant]
  @user_preference_fields [:uder_id, :property, :value]

  def start do
    Mnesia.start()

    case Mnesia.create_schema(node()) do
      {:ok, _} -> :ok
      {:error, {:already_exists, _}} -> :ok
      error -> error
    end

    Mnesia.create_table(TenantTransact,
      attributes: @tenant_transact_fields,
      type: :ordered_set,
      storage_properties: [ram_copies: [node()]]
    )

    Mnesia.add_table_index(TenantTransact, :phone_number_id)
    Mnesia.add_table_index(TenantTransact, :tenant)
    
    
    Mnesia.create_table(UserPreference,
      attributes: @user_preference_fields,
      type: :ordered_set,
      storage_properties: [ram_copies: [node()]]
    )

    Mnesia.add_table_index(UserPreference, :uder_id)
    Mnesia.add_table_index(UserPreference, :property)

  end

  def add_tenant_transact(phone_number_id, tenant) do
    Mnesia.transaction(fn ->
      Mnesia.write({
        TenantTransact,
        phone_number_id,
        tenant
      })
    end)
  end

  def get_tenant_by_phone_number_id(phone_number_id) do
    {_, result} =
      Mnesia.transaction(fn ->
        Mnesia.select(
          TenantTransact,
          [
            {
              {TenantTransact, :"$1", :"$2"},
              [{:==, :"$1", phone_number_id}],
              [:"$$"]
            }
          ]
        )
      end)

    case result do
      [[_, tenant]] -> tenant
      [] -> nil
    end
  end

  def remove_tenant_transact(phone_number_id) do
    Mnesia.transaction(fn ->
      Mnesia.delete({TenantTransact, phone_number_id})
    end)
  end
  
  
  
  def add_user_preference(user_id, property, value) do
    Mnesia.transaction(fn ->
      Mnesia.write({
        UserPreference,
        "#{user_id}_#{property}",
        property,
        value
      })
    end)
  end

  def get_user_preference(user_id, property) do
    {_, result} =
      Mnesia.transaction(fn ->
        Mnesia.select(
          UserPreference,
          [
            {
              {UserPreference, :"$1", :"$2", :"$3"},
              [{:==, :"$1", "#{user_id}_#{property}"}],
              [:"$$"]
            }
          ]
        )
      end)

    case result do
      [[_, _, value]] -> value
      [] -> nil
    end
  end
end
