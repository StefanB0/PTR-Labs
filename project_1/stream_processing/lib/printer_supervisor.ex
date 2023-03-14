defmodule PrinterSupervisor do
  use Supervisor
  require Logger

  def start_link(args \\ []) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    children = [
      {Printer, [id: :printer1]},
      {Printer, [id: :printer2]},
      {Printer, [id: :printer3]},
      {PrinterPoolManager, [printer_pool: [:printer1, :printer2, :printer3]]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
    Logger.info("PrinterSupervisor started")
  end
end
