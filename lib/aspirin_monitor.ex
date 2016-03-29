defmodule AspirinMonitor do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(AspirinMonitor.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AspirinMonitor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def test_port(address, port) do
    {:ok, ip} = address |> String.to_char_list |> :inet.parse_address
    :gen_tcp.connect(ip, port, [:binary, active: false, reuseaddr: true], 4000)
  end
end
