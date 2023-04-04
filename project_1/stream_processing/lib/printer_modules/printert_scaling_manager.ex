defmodule PrintertScalingManager do
  use GenServer
  require Logger

  # Server API

  def init(_args) do
    state = %{
      pool: [],
      pool_size: 0,
      pool_size_min: 4,
      pool_size_max: 10,
      printer_delay: Application.fetch_env!(:stream_processing, :print_delay),
      load_step: 10, # 5 messages per second
      message_count: 0,
      time_period: 3000, # in miliseconds
      time_stamp: Time.utc_now()
    }

    delay_time = Application.fetch_env!(:stream_processing, :print_delay)
    pool = Range.new(1, state.pool_size_min)
    |> Enum.map(&("printer#{&1}"))
    |> Enum.map(&String.to_atom(&1))

    Enum.each(pool, fn printer_id ->
      PrinterPoolSupervisor.add_printer(printer_id, delay_time)
      PrinterPoolManager.add_printer(printer_id)
    end)

    timer(state.time_period)
    state = %{state | pool: pool, pool_size: state.pool_size_min}
    IO.inspect(state)
    Logger.info("PrintertScalingManager started")
    {:ok, state}
  end

  defp timer(delay) do
    Process.send_after(self(), :timer, delay)
  end

  ## Server callbacks

  def handle_cast({:count_message}, state) do
    state = %{state | message_count: state.message_count + 1}
    {:noreply, state}
  end

  def handle_info(:timer, state) do
    state =
      state.message_count / Time.diff(Time.utc_now(), state.time_stamp, :second) / state.load_step
      |> Float.ceil()
      |> Kernel.round()
      |> max(state.pool_size_min)
      |> min(state.pool_size_max)
      |> Kernel.-(state.pool_size)
      |> scalePool(state)

    # log_message_freq(state)
    timer(state.time_period)
    state = %{state | message_count: 0, time_stamp: Time.utc_now()}
    {:noreply, state}
  end

  @spec scalePool(integer, map) :: map
  defp scalePool(0, state), do: state
  defp scalePool(n, state) when n > 0 do
    printer_id = "printer#{length(state.pool) + 1}" |> String.to_atom()
    add_printer(printer_id, state)
    state = %{state | pool: state.pool ++ [printer_id], pool_size: state.pool_size + 1}
    scalePool(n - 1, state)
  end
  defp scalePool(n, state) when n < 0 do
    printer_id = List.first(state.pool)
    PrinterPoolSupervisor.remove_printer(printer_id)
    PrinterPoolManager.remove_printer(printer_id)
    Logger.info("Removing printer #{printer_id}")
    state = %{state | pool: List.delete_at(state.pool, -1), pool_size: state.pool_size - 1}
    scalePool(n + 1, state)
  end

  # Client API

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def count_message() do
    GenServer.cast(__MODULE__, {:count_message})
  end

  # Logic

  def add_printer(printer_id, state) do
    # IO.puts("Adding printer #{printer_id}")
    PrinterPoolSupervisor.add_printer(printer_id, state.printer_delay)
    PrinterPoolManager.add_printer(printer_id)
  end

  defp log_message_freq(state) do
    super_pool_size = PrinterPoolSupervisor.count_printers().workers
    Logger.info("""
    \n
    Message count: #{state.message_count}
    Pool: #{state.pool |> Enum.map(&Atom.to_string/1) |> Enum.join(", ")}
    Pool size: #{state.pool_size}
    Supervisor pool size: #{super_pool_size}
    Load_step: #{state.load_step}
    Message frequency: #{state.message_count / Time.diff(Time.utc_now(), state.time_stamp, :second)} messages per second
    """)

  end
end
