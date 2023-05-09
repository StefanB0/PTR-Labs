defmodule Senders.SenderSupervisor do
  use Supervisor
  require Logger

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    Logger.info("Starting Sender Supervisor")
    children = [
      {Task.Supervisor, name: Senders.TaskSupervisor},
      Senders.Sender,
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
