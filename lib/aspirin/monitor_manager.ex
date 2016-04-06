defmodule Aspirin.MonitorManager do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def sync do
  end

  def add_port_monitor(pid, id, ip, port) do
    GenServer.call(pid, {:add_monitor, :port, id, ip, port})
  end

  def remove_monitor(pid, id) do
    GenServer.call(pid, {:remove_monitor, id})
  end

  def init(:ok) do
    {:ok, %{monitors: %{}}}
  end

  def handle_call(:sync, _from, %{monitors: _monitors}) do
  end

  def handle_call({:add_monitor, :port, id, ip, port},
                  _from, %{monitors: monitors} = state)
  when is_integer(id) and is_binary(ip) and is_integer(port) do
    case monitors do
      %{^id => _monitor} ->
        {:reply, :ok, state}
      _ ->
        {:ok, pid} = Aspirin.PortMonitor.start_link(ip, port)
        :ok = Aspirin.PortMonitor.start_monitor(pid)
        {:reply, :ok, put_in(state, [:monitors, id], %{id: id, ip: ip, port: port, pid: pid})}
    end
  end

  def handle_call({:remove_monitor, id}, _from, %{monitors: monitors} = state)
  when is_integer(id) do
    case monitors do
      %{^id => %{pid: pid}} ->
        :ok = Aspirin.PortMonitor.stop_monitor(pid)
        {:reply, :ok, %{monitors: Map.delete(monitors, id)}}
      _ ->
        {:reply, :ok, state}
    end
  end
end
