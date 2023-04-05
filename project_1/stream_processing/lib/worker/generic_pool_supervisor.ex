defmodule GenericPoolSupervisor do
  use Supervisor
  require Logger

  def start_link(args \\ [id: :pool_supervisor1]) do
    id = Keyword.fetch!(args, :id)
    Supervisor.start_link(__MODULE__, args, name: id)
  end

  @impl true
  def init(args) do
    name = Keyword.fetch!(args, :id)
    children = Keyword.fetch!(args, :children)

    Logger.info("#{name} started")
    Debugger.d_print("#{name} started", :start_up)
    Supervisor.init(children, strategy: :one_for_one)
  end

  # Client API

  def add_printer(printer_id, delay_time) do
    Supervisor.start_child(__MODULE__, {Printer, [id: printer_id, delay: delay_time]})
  end
end
