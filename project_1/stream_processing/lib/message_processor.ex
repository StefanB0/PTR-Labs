defmodule MessageProcessor do
  use GenServer
  require Logger

  # Server API
  def init(args \\ [printer_pool_manager: PrinterPoolManager]) do
    message_analyst = MessageAnalyst
    printer_pool_manager = Keyword.fetch!(args, :printer_pool_manager)
    state = %{message_analyst: message_analyst, printer_pool_manager: printer_pool_manager}
    Logger.info("MessageProcessor worker started")
    {:ok, state}
  end

  ## Server callbacks
  def handle_cast({:message, message}, state) do
    GenServer.cast(state.message_analyst, {:message, message})
    GenServer.cast(state.printer_pool_manager, {:print, message})
    {:noreply, state}
  end

  def handle_cast(:panic_message, state) do
    GenServer.cast(PrinterPoolManager, {:print, :panic_message})
    {:noreply, state}
  end

  # Client API

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # Logic

end
