defmodule Batcher do
  use GenServer
  require Logger

  # Server API

  def init(_args) do
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
    Process.cancel_timer(state.pull_timer)
    batch = state.batch ++ [tweet]
    batch = process_batch(batch, state)
    pull_timer = Process.send_after(self(), :pull_tweet, 10000)
    state = %{state | batch: batch, pull_timer: pull_timer}
    {:noreply, state}
  end

  def handle_info(:print_batch, state) do
    Logger.info("Sending Batch early")
    Process.cancel_timer(state.timer)
    Process.cancel_timer(state.pull_timer)
    send_batch(state.batch)
    timer = Process.send_after(self(), :print_batch, state.batch_expire)
    pull_timer = Process.send_after(self(), :pull_tweet, 10000)
    state = %{state | timer: timer, pull_timer: pull_timer, batch: []}
    {:noreply, state}
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

  defp process_batch(batch, true), do: send_batch(batch)
  defp process_batch(batch, false), do: batch
  defp process_batch(batch, state) do
    process_batch(batch, length(batch) >= state.batch_size)
  end

  defp check_database? do
    if GenServer.whereis(ETS.Database) == nil do
      Debugger.d_print("Database is down", :batcher)
      Process.sleep(1000)
      check_database?()
    end
    Debugger.d_print("Database is up", :batcher)
  end

  defp send_batch(batch) do
    check_database?()
    batch |> Enum.each(&ETS.Database.insert_tweet/1)
    []
  end
end
