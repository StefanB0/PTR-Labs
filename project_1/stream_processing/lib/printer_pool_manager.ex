defmodule PrinterPoolManager do
  use GenServer
  require Logger

  # Server API

  def init(args) do
    Logger.info("PrinterPoolManager started")
    {:ok, args}
  end

  ## Server callbacks

  def handle_call({:message, message}, _from, state) do
    
    {:reply, :ok, state}
  end

  # Client API

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end
end
