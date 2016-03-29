defmodule PortMonitor do
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

  def test_port(addr, port) do
    opts = [:binary, active: false, reuseaddr: true, packet: 0]
    result = with {:ok, ip} <- to_ip(addr),
         {:ok, socket} <- :gen_tcp.connect(ip, port, opts, 3000),
         do: :gen_tcp.close(socket)
    IO.puts("INFO: #{inspect result}")
    result
  end

  def init({:ok, ip, port}) do
    {:ok, %{ip: ip, port: port, time_ref: :none}}
  end

  def handle_call(:start_monitor, _from,
                  %{ip: ip, port: port, time_ref: ref} = state) do
    case state do
      %{time_ref: :none} ->
        {:ok, ref} = :timer.apply_interval(5000, __MODULE__, :test_port, [ip, port])
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
