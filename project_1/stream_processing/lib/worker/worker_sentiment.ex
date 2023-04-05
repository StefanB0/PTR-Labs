defmodule WorkerSentiment do
  use GenServer
  require Logger

  # Server API

  def init(args) do
    name = Keyword.fetch!(args, :id)
    delay_time = Keyword.fetch!(args, :delay)
    destination = Keyword.fetch!(args, :destination)

    sentiment_scores = SentimentDictionary.get_sentiment_scores()

    state = %{
      id: name,
      destination: destination,
      worker_delay: delay_time

    }

    Logger.info("Sentiment #{name} started")
    Debugger.d_print("Sentiment #{name} started", :start_up)
    {:ok, state}
  end

  def child_spec(args) do
    id = Keyword.fetch!(args, :id)

    %{
      id: id,
      start: {__MODULE__, :start_link, [args]},
      restart: :transient,
    }
  end

  ## Server callbacks

  def handle_cast({:panic_message}, state) do
    IO.ANSI.format([:red, "Worker #{state.id} panics and crashes"]) |> IO.puts()
    {:stop, :panic, state}
    {:noreply, state}
  end

  def handle_cast({:tweet, tweet, from}, state) do
    delay(state.worker_delay)
    tweet = %{tweet | sentimental_score: sentimental_score(tweet)}
    GenServer.cast(state.destination, {:tweet, tweet})

    GenericLoadBalancer.worker_done(from, state.id)
    {:noreply, state}
  end

  # Client API

  def panic(printer_address) do
    GenServer.cast(printer_address, {:panic_message})
  end

  def least_loaded(printer_address, tweet, from) do
    GenServer.cast(printer_address, {:tweet, tweet, from})
  end

  def start_link(args) do
    name = Keyword.fetch!(args, :id)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  # Logic

  defp delay(time), do: Process.sleep(time)

  defp sentimental_score(_tweet), do: 42
end
