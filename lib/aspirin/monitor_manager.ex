defmodule Aspirin.MonitorManager do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def sync_repo(pid) do
    GenServer.call(pid, :sync_repo)
  end

  def reset(pid) do
    GenServer.call(pid, :reset)
  end

  def add_port_monitor(pid, id, ip, port) do
    GenServer.call(pid, {:add_monitor, :port, id, ip, port})
  end

  def remove_monitor(pid, id) do
    GenServer.call(pid, {:remove_monitor, id})
  end

  def init(:ok) do
    {:ok, initial_state}
  end

  def handle_call(:reset, _from, state) do
    {:reply, :ok, stop_all(state)}
  end

  def handle_call(:sync_repo, _from, %{monitors: _monitors} = state) do
    import Ecto.Query, only: [from: 2]
    events = from(m in Aspirin.MonitorEvent, where: m.enabled == "true")
    |> Aspirin.Repo.all

    new = Enum.reduce(events, stop_all(state), fn(monitor, acc) ->
      {:ok, acc} = add_monitor(:port, monitor.id, monitor.addr, monitor.port, acc)
      acc
    end)
    {:reply, :ok, new}
  end

  def handle_call({:add_monitor, :port, id, ip, port}, _from, state) do
    {:ok, state} = add_monitor(:port, id, ip, port, state)
    {:reply, :ok, state}
  end

  def handle_call({:remove_monitor, id}, _from, %{monitors: monitors} = state)
  when is_integer(id) do
    case monitors do
      %{^id => %{pid: pid}} ->
        :ok = Aspirin.PortMonitor.stop(pid)
        {:reply, :ok, %{monitors: Map.delete(monitors, id)}}
      _ ->
        {:reply, :ok, state}
    end
  end

  defp stop_all(%{monitors: monitors}) do
    monitors |> Map.values |> Enum.each(fn(%{pid: pid}) ->
      :ok = Aspirin.PortMonitor.stop(pid)
    end)
    initial_state
  end

  defp add_monitor(:port, id, ip, port, %{monitors: monitors} = state)
  when is_integer(id) and is_binary(ip) and is_integer(port) do
    case monitors do
      %{^id => _monitor} ->
        {:ok, state}
      _ ->
        {:ok, pid} = Aspirin.PortMonitor.start_link(ip, port)
        :ok = Aspirin.PortMonitor.start_monitor(pid)
        new = put_in(state, [:monitors, id], %{id: id, ip: ip, port: port, pid: pid})
        IO.puts("[INFO] new state: " <> inspect(new))
        {:ok, new}
    end
  end

  defp initial_state do
    %{monitors: %{}}
  end
end
