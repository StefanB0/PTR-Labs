defmodule WorkerPrinter do
  use GenServer
  require Logger

  # Server API

  def init(args) do
    name = Keyword.fetch!(args, :id)
    delay_time = Keyword.fetch!(args, :delay)
    state = %{worker_delay: delay_time, id: name}
    Logger.info("Printer #{name} started")
    Debugger.d_print("Printer #{name} started", :start_up)
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
    print_text(tweet)

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

  defp print_text(tweet) do
    # tweet_text = tweet.text |> censor()

    if !Debugger.check_debug() do
      tweet.text <> "\n" <>
      "Engagement ratio: #{tweet.engagement_ratio}, Sentiment score #{tweet.sentimental_score}" <> "\n---"
      |> IO.puts()
    end
    Debugger.d_print(tweet.text, :printer)
  end

  def censor(text) do
    text
    |> String.split()
    |> Enum.map(fn word ->
        censor_word?(word) && (String.graphemes(word) |> Enum.map(fn _ -> "*" end) |> Enum.join())
        || word
      end)
    |> Enum.join(" ")
  end

  defp censor_word?(word), do: CensorList.get_word_list()|> Enum.member?(word |> String.downcase())
end
