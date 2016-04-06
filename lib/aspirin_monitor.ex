defmodule AspirinMonitor do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Task.Supervisor,
        [[name: Aspirin.MonitorManager.TaskSupervisor]]),
      worker(Aspirin.MonitorManager, [[name: Aspirin.MonitorManager]])
    ]

    opts = [strategy: :one_for_one, name: AspirinMonitor.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
