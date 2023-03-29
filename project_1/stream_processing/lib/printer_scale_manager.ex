# defmodule PrinterScaleManager do
#   use GenServer

#   # Server API

#   def init(args) do
#     printer_nr = Keyword.fetch!(args, :printer_nr)
#     min_printer_nr = Keyword.fetch!(args, :min_printer_nr)
#     max_printer_nr = Keyword.fetch!(args, :max_printer_nr)
#     load_step = Keyword.fetch!(args, :load_step)
#     printer_supervisor = Keyword.fetch!(args, :printer_supervisor)
#     state = %{
#       printer_supervisor: printer_supervisor,
#       printer_nr: printer_nr,
#       load: 0,
#       timestamp: Time.utc_now(),
#       min_printer_nr: min_printer_nr,
#       max_printer_nr: max_printer_nr,
#       load_step: load_step
#     }

#     time_tick()
#     {:ok, state}
#   end

#   ## Server callbacks

#   # def handle_info(:tick, state) do
#   #   {status, printer_nr} = check_load(state)

#   #   case status do
#   #     :change -> change_load(printer_nr)
#   #     :no_change -> nil
#   #   end

#   #   state = reset_state(state, printer_nr)
#   #   time_tick()
#   #   {:noreply, state}
#   # end

#   def handle_cast(:print, state) do
#     state = %{state | load: state.load + 1}
#     {:noreply, state}
#   end

#   # Client API
#   def start_link(args) do
#     GenServer.start_link(__MODULE__, args, name: __MODULE__)
#   end

#   def print_notice() do
#     GenServer.cast(__MODULE__, :print)
#   end

#   # Logic
#   defp time_tick() do
#     Process.send_after(self(), :tick, 5000)
#   end

#   defp check_load(state) do
#     duration = Time.diff(Time.utc_now(), state.timestamp)
#     current_load = duration / state.load
#     IO.ANSI.format([:red, "Current load: #{current_load}"]) |> IO.puts()
#     printer_nr = current_load / state.load_step
#     printer_nr = max(state.min_printer_nr, printer_nr)
#     printer_nr = min(state.max_printer_nr, printer_nr)
#     diff = printer_nr - state.printer_nr

#     cond do
#       diff != 0 -> {:change, printer_nr}
#       true -> {:no_change, printer_nr}
#     end
#   end

#   # defp change_load(pool_size) do
#   #   PrinterPoolManager.resize_pool(pool_size)
#   # end

#   defp reset_state(state, printer_nr) do
#   %{
#     state |
#       timestamp: Time.utc_now(),
#       printer_nr: printer_nr,
#       load: 0
#   }
#   end
# end
