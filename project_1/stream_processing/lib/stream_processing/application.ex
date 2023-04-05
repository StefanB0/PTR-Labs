defmodule StreamProcessing.Application do
  @moduledoc false
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Application started")
    Debugger.d_print("Application started", :start_up)

    # children = [
    #   PrinterSupervisor,
    #   MessageAnalyst,
    #   {MessageProcessor, [message_analyst: MessageAnalyst, printer_pool_manager: PrinterPoolManager]},
    #   ReaderSupervisor
    # ]

    children = [
      CensorList,
      SentimentDictionary,
      {MessageAnalyst, []},

      {WorkerPrinter, [id: :worker4, delay: 1000]},
      {GenericLoadBalancer, [name: :load_balancer4, pool: [:worker4], worker_type: WorkerPrinter]},

      {WorkerSentiment, [id: :worker3, destination: :load_balancer4, delay: 1000]},
      {GenericLoadBalancer, [name: :load_balancer3, pool: [:worker3], worker_type: WorkerSentiment]},

      {WorkerEngagement, [id: :worker2, destination: :load_balancer3, delay: 1000]},
      {GenericLoadBalancer, [name: :load_balancer2, pool: [:worker2], worker_type: WorkerEngagement]},

      {WorkerRedacter, [id: :worker1, destination: :load_balancer2, delay: 1000]},
      {GenericLoadBalancer, [name: :load_balancer1, pool: [:worker1], worker_type: WorkerRedacter]},

      {MessageProcessor, [message_analyst: MessageAnalyst, load_balancer: :load_balancer1]},
      {DummyReader, [id: :dummy_reader1]},
    ]

    opts = [strategy: :one_for_one, name: StreamProcessing.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
