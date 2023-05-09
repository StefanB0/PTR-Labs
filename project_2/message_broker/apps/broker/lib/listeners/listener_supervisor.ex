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
      # Listeners.Cdc,
      # Listeners.MQTTListener,
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

# Consumer API
# Connect
# Re-connect
# Subscribe to topic
# Subscribe to publisher
# Unsubscribe
#
# Publish received (PUBREC)
# Publish complete (PUBCOMP)

# Publisher API
# Connect
# Publish to topic
# Publish release (PUBREL)
