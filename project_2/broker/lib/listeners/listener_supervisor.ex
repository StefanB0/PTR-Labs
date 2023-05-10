defmodule Listeners.ListenerSupervisor do
  use Supervisor
  require Logger

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    Logger.info("Starting Listener Supervisor")
    children = [
      {Task.Supervisor, name: Listeners.TaskSupervisor},
      Listeners.TCPListener,
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
