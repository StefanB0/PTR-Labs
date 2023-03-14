defmodule MessageProcessor do
  use GenServer
  require Logger

  # Server API

  def init(args) do
    Logger.info("MessageProcessor worker started")
    {:ok, args}
  end

  ## Server callbacks

  def handle_cast({:message, message}, state) do
    message = Map.put(message, :data, Jason.decode!(message.data, keys: :atoms))

    GenServer.cast(MessageAnalyst, {:message, message})
    GenServer.cast(PrinterPoolManager, {:print, message})
    {:noreply, state}
  end

  def handle_cast(:panic_message, state) do
    GenServer.cast(PrinterPoolManager, :{:print, :panic_message})
    {:noreply, state}
  end

  # Client API

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end
end
