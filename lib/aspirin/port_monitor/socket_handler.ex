defmodule PortMonitor.SocketHandler do
  use GenEvent
  import Aspirin.Endpoint, only: [broadcast!: 3]

  def handle_event({:test_port, addr, port, result}, _state) do
    IO.puts("[BROADCAST] #{inspect result}")
    msg = %{addr: addr, port: port}
    case result do
      :ok ->
        msg = put_in(msg, [:body], :success)
        broadcast!("status:all", "test_port", msg)
      {:error, reason} ->
        msg = Map.merge(msg, %{body: :failure, reason: reason})
        broadcast!("status:all", "test_port", msg)
    end
    {:ok, []}
  end
end
