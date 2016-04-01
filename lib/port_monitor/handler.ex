defmodule PortMonitor.Handler do
  use GenEvent

  def handle_event({:test_port, result}, _state) do
    IO.puts("[INFO] #{inspect result}")
    {:ok, []}
  end
end
