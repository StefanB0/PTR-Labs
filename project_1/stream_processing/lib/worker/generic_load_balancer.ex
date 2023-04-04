defmodule GenericLoadBalancer do
  use GenServer
  require Logger

  # Server API

  def init(args) do
    name = Keyword.fetch!(args, :name)
    pool = Keyword.fetch!(args, :pool)
    state = %{
      pool: Enum.map(pool, fn p -> {p, 0} end) |> Map.new(),
      message_queue: [],
      message_iterator: 0
    }

    Logger.info("#{name} started")
    {:ok, state}
  end

  ## Server callbacks

  def handle_cast({:add_printer, printer_address}, state) do
    state = %{state | pool: Map.put(state.pool, printer_address, 0)}
    {:noreply, state}
  end

  def handle_cast({:remove_printer, printer_address}, state) do
    state = %{
      state
      | pool: Map.delete(state.pool, printer_address)
    }

    {:noreply, state}
  end

  def handle_cast({:print, :panic_message}, state) do
    state
    |> Map.get(:pool)
    |> Enum.min_by(fn {_p, c} -> c end)
    |> elem(0)
    |> Printer.panic()

    {:noreply, state}
  end

  def handle_cast({:print, message}, state) do
    {printer_address, printer_score} =
      state
      |> Map.get(:pool)
      |> Enum.min_by(fn {_p, c} ->
        c
      end)

    PrintertScalingManager.count_message()
    Printer.least_loaded_print(printer_address, message, state.message_iterator)

    state = %{
      state
      | pool: %{state.pool | printer_address => printer_score + 1},
        message_queue: state.message_queue ++ [{state.message_iterator, Time.utc_now()}],
        message_iterator: state.message_iterator + 1
    }

    {:noreply, state}
  end

  def handle_cast({:print, :done, printer_id, _iterator}, state) do
    score = Map.get(state.pool, printer_id)

    state = %{
      state
      | pool: %{state.pool | printer_id => score - 1}
    }

    {:noreply, state}
  end

  # def handle_cast({:resize_pool, pool_size}, state) do
  #   new_pool = state.pool_size
  #   |> Kernel.>=(pool_size)
  #   |> p_resize(state, pool_size)

  #   state = %{
  #     state |
  #       pool_size: pool_size,
  #       pool: new_pool
  #   }

  #   {:noreply, state}
  # end

  # defp p_resize(true, state, pool_size) do
  #   state.pool |> Map.to_list() |> Enum.drop(pool_size) |> Enum.map(fn {p, _v} -> p end) |> Enum.each(fn p -> Supervisor.terminate_child(state.supervisor, p) end)
  #   state.pool |> Map.to_list() |> Enum.take(pool_size) |> Map.new()
  # end

  # defp p_resize(false, state, pool_size) do
  #   delay = Application.fetch_env!(:stream_processing, :print_delay)

  #   Range.new(state.pool_size + 1, pool_size)
  #   |> Enum.map(fn i -> "printer" <> Integer.to_string(i) |> String.to_atom() end)
  #   |> Enum.map(fn p -> PrinterSupervisor.add_printer(state.supervisor, p, delay) ; p end)
  #   |> Enum.map(fn p -> {p, 0} end)
  #   |> Map.new()
  # end

  # Client API

  def start_link(args \\ [printer_pool: Printer]) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def print_done(printer_id, iterator) do
    GenServer.cast(__MODULE__, {:print, :done, printer_id, iterator})
  end

  def add_printer(printer_address) do
    GenServer.cast(__MODULE__, {:add_printer, printer_address})
  end

  def remove_printer(printer_address) do
    GenServer.cast(__MODULE__, {:remove_printer, printer_address})
  end

  # def resize_pool(pool_size) do
  #   GenServer.cast(__MODULE__, {:resize_pool, pool_size})
  # end
end
