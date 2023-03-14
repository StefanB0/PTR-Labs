defmodule MessageProcessor do
  use GenServer
  require Logger

  # Server API

  def init(args) do
    Logger.info("MessageProcessor worker started")
    {:ok, args}
  end

  ## Server callbacks

  def handle_call({:message, message}, _from, state) do
    message = Map.put(message, :data, Jason.decode!(message.data, keys: :atoms))

    GenServer.call(state.analyst, {:message, message})
    GenServer.call(state.printer, {:print, message})
    {:reply, :ok, state}
  end

  # Client API

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end
end
