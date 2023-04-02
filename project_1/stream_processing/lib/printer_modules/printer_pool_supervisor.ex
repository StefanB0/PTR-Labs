defmodule PrinterPoolSupervisor do
  use Supervisor
  require Logger

  def start_link(args \\ []) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = []

    Logger.info("PrinterPoolSupervisor started")
    Supervisor.init(children, strategy: :one_for_one)
  end

  # Client API

  def add_printer(printer_id, delay_time) do
    Supervisor.start_child(__MODULE__, {Printer, [id: printer_id, delay: delay_time]})
    Logger.info("Adding printer #{printer_id}")
  end

  def remove_printer(id) do
    Supervisor.terminate_child(__MODULE__, id)
    Supervisor.delete_child(__MODULE__, id)
  end

  def list_printers() do
    Supervisor.which_children(__MODULE__)
    |> Enum.map(fn {id, _, _, _} -> id end)
  end

  def count_printers() do
    Supervisor.count_children(__MODULE__)
  end
end
