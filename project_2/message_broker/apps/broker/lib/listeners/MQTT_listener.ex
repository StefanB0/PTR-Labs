defmodule Listeners.MQTTListener do
  use Task, restart: :permanent, shutdown: 5000
  require Logger

  def start_link(_args) do
    Logger.info("Starting MQTT Listener")
    port = Application.get_env(:broker, :tcp_port)
    Task.start_link(__MODULE__, :listen, [port])
  end

  def listen(port) do
    Process.sleep(10000)
    listen(port)
  end
end
