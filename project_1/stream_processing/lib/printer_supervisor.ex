defmodule PrinterSupervisor do
  use Supervisor
  require Logger

  def start_link(args \\ []) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    delay_time = Application.fetch_env!(:stream_processing, :print_delay)
    children = [
      {Printer, [id: :printer1, delay: delay_time]},
      {Printer, [id: :printer2, delay: delay_time]},
      {Printer, [id: :printer3, delay: delay_time]},
      {PrinterPoolManager, [printer_pool: [:printer1, :printer2, :printer3]]}
    ]

    Logger.info("PrinterSupervisor started")
    Supervisor.init(children, strategy: :one_for_one)
  end
end
