defmodule StreamProcessing.Application do
  @moduledoc false
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Application started")
    Debugger.d_print("Application started", :start_up)

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

      {MessageProcessor, [message_analyst: MessageAnalyst, load_balancer: supervisor_redacter.balancer_address]},
      # ReaderSupervisor,
      {DummyReader, [id: :dummy_reader1]}
    ]

    opts = [strategy: :one_for_one, name: StreamProcessing.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
