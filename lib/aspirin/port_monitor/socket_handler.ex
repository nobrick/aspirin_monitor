defmodule PortMonitor.SocketHandler do
  use GenEvent
  import Aspirin.Endpoint, only: [broadcast!: 3]

  def handle_event({:test_port, addr, port, result, last_ok_time}, _state) do
    Application.ensure_all_started(Aspirin)
    import Aspirin.MonitorEventView, only: [css_identity: 3]
    css_id = css_identity(:port, addr, port)
    msg = %{addr: addr,
            port: port,
            identity: css_id,
            timestamp: :os.system_time(:milli_seconds),
            last_ok_time: last_ok_time}
    IO.puts("[BROADCAST] #{inspect result} @ #{inspect msg}")
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
