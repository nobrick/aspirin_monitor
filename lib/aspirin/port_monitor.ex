defmodule Aspirin.PortMonitor do
  use GenServer

  def start_link(ip, port) do
    GenServer.start_link(__MODULE__, {:ok, ip, port}, [])
  end

  def start_monitor(server) do
    GenServer.call(server, :start_monitor)
  end

  def stop_monitor(server) do
    GenServer.call(server, :stop_monitor)
  end

  @inet_opts [:binary, active: false, reuseaddr: true, packet: 0]

  def test_port(addr, port) do
    result = with {:ok, ip} <- to_ip(addr),
         {:ok, socket} <- :gen_tcp.connect(ip, port, @inet_opts, 3000),
         do: :gen_tcp.close(socket)
    result
  end

  def test_port_and_notify(addr, port, event_manager) do
    result = test_port(addr, port)
    GenEvent.notify(event_manager, {:test_port, addr, port, result})
  end

  def init({:ok, ip, port}) do
    {:ok, manager} = GenEvent.start_link([])
    GenEvent.add_handler(manager, PortMonitor.SocketHandler, [])
    {:ok, %{ip: ip, port: port, time_ref: :none, event_manager: manager}}
  end

  def handle_call(:start_monitor, _from,
                  %{ip: ip, port: port, time_ref: ref, event_manager: manager} = state) do
    case state do
      %{time_ref: :none} ->
        {:ok, ref} = :timer.apply_interval(5000,
                                          __MODULE__,
                                          :test_port_and_notify,
                                          [ip, port, manager])
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
