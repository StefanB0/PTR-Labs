defmodule Batcher do
  use GenServer
  require Logger

  # Server API

  def init(_args) do
    # batch_size = Keyword.fetch!(args, :batch_size)
    # batch_expire = Keyword.fetch!(args, :batch_expire)
    batch_size = Application.get_env(:stream_processing, :batch_size)
    batch_expire = Application.get_env(:stream_processing, :batch_expire)
    timer = Process.send_after(self(), :print_batch, batch_expire)
    pull_timer = Process.send_after(self(), :pull_tweet, 10000)

    state = %{
      batch: [],
      batch_size: batch_size,
      batch_expire: batch_expire,
      timer: timer,
      pull_timer: pull_timer
    }

    pull_tweet(state)
    Logger.info("Batcher worker started")
    Debugger.d_print("Batcher worker started", :start_up)
    {:ok, state}
  end

  ## Server callbacks

  def handle_cast({:tweet, tweet}, state) do
    # Debugger.d_print("Tweet received, #{tweet.tweet_id}", :batcher)
    batch = state.batch ++ [tweet]
    {batch, timer} = process_batch(batch, state)
    state = %{state | batch: batch, timer: timer}
    state = pull_tweet(state)
    {:noreply, state}
  end

  def handle_info(:print_batch, state) do
    IO.puts("\n\n---Partially printing batch---\n\n")
    print_batch(state.batch)
    timer = Process.send_after(self(), :print_batch, state.batch_expire)
    Debugger.d_print("Timer procced", :batcher)
    {:noreply, %{state | batch: [], timer: timer}}
  end

  def handle_info(:pull_tweet, state) do
    Debugger.d_print("Pulling tweets", :batcher)
    state = pull_tweet(state)
    {:noreply, state}
  end

  ## Client API

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def send_tweet(tweet) do
    GenServer.cast(__MODULE__, {:tweet, tweet})
  end

  ## Logic

  defp pull_tweet(state) do
    Aggregator.get_tweet()
    Process.cancel_timer(state.pull_timer)
    %{state | pull_timer: Process.send_after(self(), :pull_tweet, 10000)}
  end

  defp process_batch(batch, state) do
    process_batch(batch, state, length(batch) >= state.batch_size)
  end

  defp process_batch(batch, state, true) do
    print_batch(batch)
    Process.cancel_timer(state.timer)
    timer = Process.send_after(self(), :print_batch, state.batch_expire)
    {[], timer}
  end

  defp process_batch(batch, state, false), do: {batch, state.timer}

  defp print_batch([]), do: nil

  defp print_batch(batch) do
    IO.puts("\n\n---Batch Start---")
    batch |> Enum.each(&print_tweet/1)
    IO.puts("---Batch Finish---")
  end

  defp print_tweet(tweet) do
    (tweet.text <>
       "\n" <>
       "Engagement ratio: #{tweet.engagement_ratio}, Sentiment score #{tweet.sentimental_score}" <>
       "\n---")
    |> IO.puts()
  end
end
