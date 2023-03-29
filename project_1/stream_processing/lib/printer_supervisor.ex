defmodule PrinterSupervisor do
  use Supervisor
  require Logger

  def start_link(args \\ []) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    children = [
      CensorList,
      # {Printer, [id: :printer1, delay: delay_time]},
      # {Printer, [id: :printer2, delay: delay_time]},
      # {Printer, [id: :printer3, delay: delay_time]},
      # {Printer, [id: :printer4, delay: delay_time]},
      {PrinterDynamicSupervisor, []},
      {PrinterPoolManager, [printer_pool: []]}, #[:printer1, :printer2, :printer3, :printer4]]}
      {PrintertScalingManager, []},
    ]

    Logger.info("PrinterSupervisor started")
    Supervisor.init(children, strategy: :one_for_one)
  end

  # Client API

  def add_printer(printer_id, delay_time) do
    Supervisor.start_child(__MODULE__, {Printer, [id: printer_id, delay: delay_time]})
  end
end
