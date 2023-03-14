defmodule PrinterPoolManager do
  use GenServer
  require Logger

  # Server API

  def init(args) do
    printer_pool = Keyword.fetch!(args, :printer_pool)
    # state = %{pool: printer_pool, pointer: 0}
    state = %{pool: Enum.map(printer_pool, fn p -> {p, 0} end) |> Map.new()}

    Logger.info("PrinterPoolManager started")
    {:ok, state}
  end

  ## Server callbacks

  def handle_cast({:print, message}, state) do
    {printer_address, printer_score} =
      state
      |> Map.get(:pool)
      |> Enum.min_by(fn {_p, c} ->
        c
      end)

    Printer.least_loaded_print(printer_address, message)
    state = %{state | pool: %{state.pool | printer_address => printer_score + 1}}
    {:noreply, state}
  end

  def handle_cast({:print, :done, printer_id}, state) do
    score = Map.get(state.pool, printer_id)
    state = %{state | pool: %{state.pool | printer_id => score - 1}}
    {:noreply, state}
  end

  # Client API

  def start_link(args \\ [printer_pool: Printer]) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def print_done(printer_id) do
    GenServer.cast(__MODULE__, {:print, :done, printer_id})
  end
end
