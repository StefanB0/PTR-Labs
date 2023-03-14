defmodule PrinterPoolManager do
  use GenServer
  require Logger

  # Server API

  def init(args) do
    printer_pool = Keyword.fetch!(args, :printer_pool)
    state = %{pool: printer_pool, pointer: 0}
    Logger.info("PrinterPoolManager started")
    {:ok, state}
  end

  ## Server callbacks

  def handle_cast({:print, message}, state) do
    p = Map.get(state, :pointer)

    state
    |> Map.get(:pool)
    |> Enum.at(p)
    |> GenServer.cast({:print, message})

    state = %{state | pointer: rem(p + 1, Enum.count(state.pool))}
    {:noreply, state}
  end

  # Client API

  def start_link(args \\ [printer_pool: Printer]) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end
end
