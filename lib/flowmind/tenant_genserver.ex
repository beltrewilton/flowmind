defmodule Flowmind.TenantGenServer do
  use GenServer
  
  # Client API
  # 
  def start_link(_) do
    IO.inspect("TenantGenServer")
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end
  
  def put_tenant(tenant) do
    GenServer.call(__MODULE__, {:put_tenant, tenant})
  end
  
  def get_tenant() do
    GenServer.call(__MODULE__, :get_tenant)
  end
  
  def remove_tenant() do
    GenServer.call(__MODULE__, :remove_tenant)
  end
  
  # Server callbacks

  @impl true
  def init(state) do
    IO.inspect("TenantGenServer -> init")
    {:ok, state}
  end
  
  @impl true
  def handle_call({:put_tenant, tenant}, from, state) do
    IO.inspect(from, label: "PID -> put")
    {:reply, :ok, Map.put(state, :tenant, tenant)}
  end
  
  @impl true
  def handle_call(:get_tenant, from, state) do
    IO.inspect(from, label: "PID -> getting")
    {:reply, Map.get(state, :tenant, "tenant_not_found_in_genserver"), state}
  end
  
  @impl true
  def handle_call(:remove_tenant, from, state) do
    IO.inspect(from, label: "PID -> remove")
    {:reply, :ok, Map.delete(state, :tenant)}
  end
  
end