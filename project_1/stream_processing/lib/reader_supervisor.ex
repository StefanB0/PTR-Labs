defmodule ReaderSupervisor do
  use Supervisor
  require Logger

  def start_link(args \\ []) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    Logger.info("ReaderSupervisor started")
    url1 = Application.fetch_env!(:stream_processing, :eventsource_tweet_url_1)
    url2 = Application.fetch_env!(:stream_processing, :eventsource_tweet_url_2)

    children = [
      {SSEReader, [id: :sse_reader1, url: url1, destination: MessageProcessor]},
      {SSEReader, [id: :sse_reader2, url: url2, destination: MessageProcessor]},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
