defmodule PortMonitor.SocketHandler do
  use GenEvent
  alias Aspirin.Endpoint.broadcast!

  def handle_event({:test_port, result}, _state) do
    IO.puts("[BROADCAST] #{inspect result}")
    case result do
      :ok ->
        msg = %{body: :success}
        broadcast!("status:all", "test_port", msg)
      {:error, reason} ->
        msg = %{body: :failure, reason: reason}
        broadcast!("status:all", "test_port", msg)
    end
    {:ok, []}
  end
end
