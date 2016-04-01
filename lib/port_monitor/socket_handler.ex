defmodule PortMonitor.SocketHandler do
  use GenEvent

  def handle_event({:test_port, result}, _state) do
    IO.puts("[INFO] #{inspect result}")
    Phoenix.Channel.broadcast!(Aspirin.UserSocket, "test_port", result)
    {:ok, []}
  end
end
