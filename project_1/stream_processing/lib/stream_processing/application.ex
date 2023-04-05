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
    # pool_supervisor = GenericPoolSupervisor.generic_pool_super(1, 3, :load_balancer3, WorkerEngagement)
    supervisor_printer = GenericPoolSupervisor.generic_pool_super(1, 3, :none, WorkerPrinter)
    supervisor_sentiment = GenericPoolSupervisor.generic_pool_super(1, 3, supervisor_printer.balancer_address, WorkerSentiment)
    supervisor_engagement = GenericPoolSupervisor.generic_pool_super(1, 3, supervisor_sentiment.balancer_address , WorkerEngagement)
    supervisor_redacter = GenericPoolSupervisor.generic_pool_super(1, 3, supervisor_engagement.balancer_address, WorkerRedacter)

    children = [
      CensorList,
      SentimentDictionary,
      {MessageAnalyst, []},

      supervisor_printer.spec,
      supervisor_sentiment.spec,
      supervisor_engagement.spec,
      supervisor_redacter.spec,

      # {WorkerPrinter, [id: :worker4, delay: 1000]},
      # {GenericLoadBalancer, [name: :load_balancer4, pool: [:worker4], worker_type: WorkerPrinter]},

      # {WorkerSentiment, [id: :worker3, destination: :load_balancer4, delay: 1000]},
      # {GenericLoadBalancer, [name: :load_balancer3, pool: [:worker3], worker_type: WorkerSentiment]},

      # pool_supervisor.spec,
      # {WorkerEngagement, [id: :worker2, destination: :load_balancer3, delay: 1000]},
      # {GenericLoadBalancer, [name: :load_balancer2, pool: [:worker2], worker_type: WorkerEngagement]},

      # {WorkerRedacter, [id: :worker1, destination: pool_supervisor.balancer_address, delay: 1000]},
      # {GenericLoadBalancer, [name: :load_balancer1, pool: [:worker1], worker_type: WorkerRedacter]},

      {MessageProcessor, [message_analyst: MessageAnalyst, load_balancer: supervisor_redacter.balancer_address]},
      ReaderSupervisor
      # {DummyReader, [id: :dummy_reader1]},
    ]

    opts = [strategy: :one_for_one, name: StreamProcessing.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
