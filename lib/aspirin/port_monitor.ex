defmodule Aspirin.PortMonitor do
  use GenServer

  def start_link(ip, port) do
    GenServer.start_link(__MODULE__, {:ok, ip, port}, [])
  end

  def stop(server) do
    stop_monitor(server)
    GenServer.stop(server)
  end

  def start_monitor(server), do: GenServer.call(server, :start_monitor)
  def stop_monitor(server), do: GenServer.call(server, :stop_monitor)

  def set_last_ok_time(server), do: set_last_ok_time(server, time_now)

  def set_last_ok_time(server, time) do
    {:ok, _} = GenServer.call(server, {:set_last_ok_time, time})
    time
  end

  def get_last_ok_time(server) do
    {:ok, time} = GenServer.call(server, {:get_last_ok_time})
    time
  end

  def time_now do
    :os.system_time(:milli_seconds)
  end

  @inet_opts [:binary, active: false, reuseaddr: true, packet: 0]

  def test_port(addr, port, port_monitor) do
    result = with {:ok, ip} <- to_ip(addr),
         {:ok, socket} <- :gen_tcp.connect(ip, port, @inet_opts, 3000),
         do: :gen_tcp.close(socket)
    time = case result do
      :ok -> set_last_ok_time(port_monitor)
      _   -> get_last_ok_time(port_monitor)
    end
    {result, time}
  end

  def test_port_and_notify(addr, port, event_manager, port_monitor) do
    {result, time} = test_port(addr, port, port_monitor)
    GenEvent.notify(event_manager, {:test_port, addr, port, result, time})
  end

  ## Callbacks

  def init({:ok, ip, port}) do
    {:ok, manager} = GenEvent.start_link([])
    GenEvent.add_handler(manager, Aspirin.PortMonitor.SocketHandler, [])
    {:ok, %{ip: ip,
      port: port,
      time_ref: :none,
      event_manager: manager,
      last_ok_time: time_now}}
  end

  def handle_call({:set_last_ok_time, time}, _from, state) do
    {:reply, {:ok, time}, %{state | last_ok_time: time}}
  end

  def handle_call({:get_last_ok_time}, _from, %{last_ok_time: time} = state) do
    {:reply, {:ok, time}, state}
  end

  def handle_call(:start_monitor, _from,
                  %{ip: ip, port: port, time_ref: ref, event_manager: manager} = state) do
    case state do
      %{time_ref: :none} ->
        {:ok, ref} = :timer.apply_interval(5000,
                                          __MODULE__,
                                          :test_port_and_notify,
                                          [ip, port, manager, self()])
        {:reply, :ok, %{state | time_ref: ref}}
      %{time_ref: _ref} ->
        {:reply, :ok, state}
    end
  end

  def handle_call(:stop_monitor, _from, %{time_ref: :none} = state) do
    {:reply, :ok, state}
  end
  def handle_call(:stop_monitor, _from, %{time_ref: ref} = state) do
    :timer.cancel(ref)
    {:reply, :ok, %{state | time_ref: :none}}
  end

  defp to_ip(addr) when is_binary(addr) do
    addr |> String.to_char_list |> :inet.parse_address
  end
  defp to_ip(addr) when is_tuple(addr), do: addr
end
