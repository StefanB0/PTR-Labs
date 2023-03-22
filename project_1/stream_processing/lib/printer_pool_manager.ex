defmodule PrinterPoolManager do
  use GenServer
  require Logger

  # Server API

  def init(args) do
    printer_pool = Keyword.fetch!(args, :printer_pool)
    # state = %{pool: printer_pool, pointer: 0}
    state = %{
      pool: Enum.map(printer_pool, fn p -> {p, 0} end) |> Map.new(),
      message_queue: [],
      message_iterator: 0
    }

    Logger.info("PrinterPoolManager started")
    {:ok, state}
  end

  ## Server callbacks

  def handle_cast({:print, :panic_message}, state) do
    state
    |> Map.get(:pool)
    |> Enum.min_by(fn {_p, c} -> c end)
    |> elem(0)
    |> Printer.least_loaded_print(:panic_message, 0)

    {:noreply, state}
  end

  def handle_cast({:print, message}, state) do
    {printer_address, printer_score} =
      state
      |> Map.get(:pool)
      |> Enum.min_by(fn {_p, c} ->
        c
      end)

    Printer.least_loaded_print(printer_address, message, state.message_iterator)
    state = %{
      state |
        pool: %{state.pool | printer_address => printer_score + 1},
        message_queue: state.message_queue ++ [{state.message_iterator, Time.utc_now()}],
        message_iterator: state.message_iterator + 1
    }
    {:noreply, state}
  end

  def handle_cast({:print, :done, printer_id}, state) do
    score = Map.get(state.pool, printer_id)
    state = %{
      state |
        pool: %{state.pool | printer_id => score - 1},
      }
    {:noreply, state}
  end

  # Client API

  def start_link(args \\ [printer_pool: Printer]) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def print_done(printer_id, iterator) do
    GenServer.cast(__MODULE__, {:print, :done, printer_id, iterator})
  end
end
