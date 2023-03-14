defmodule StreamProcessing.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Application started")

    children = [
      Printer,
      MessageAnalyst,
      {MessageProcessor, %{analyst: MessageAnalyst, printer: Printer}},
      ReaderSupervisor
    ]

    opts = [strategy: :one_for_one, name: StreamProcessing.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
