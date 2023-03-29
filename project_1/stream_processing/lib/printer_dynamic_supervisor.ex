defmodule PrinterDynamicSupervisor do
  use DynamicSupervisor
  require Logger

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Logger.info("PrinterDynamicSupervisor started")
    DynamicSupervisor.init(strategy: :one_for_one, max_children: 10)
  end

  # Client API

  def add_printer(printer_id, delay_time) do
    DynamicSupervisor.start_child(__MODULE__, {Printer, [id: printer_id, delay: delay_time]})
  end

  def remove_printer(_printer_id) do
    pid = get_pid()
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  defp get_pid() do
    {_, pid, _, _} =
      DynamicSupervisor.which_children(__MODULE__)
      |> List.last()
      pid
  end

  def list_printers() do
    DynamicSupervisor.which_children(__MODULE__)
  end

  def count_printers() do
    DynamicSupervisor.count_children(__MODULE__)
  end
end
