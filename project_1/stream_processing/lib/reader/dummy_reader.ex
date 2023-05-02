defmodule DummyReader do
  use GenServer
  require Logger
  # Server API

  def init(args) do
    Debugger.d_print("DummyReader started", :start_up)
    send(self(), :loop)
    {:ok, args}
  end

  def child_spec(args) do
    id = Keyword.fetch!(args, :id)

    %{
      id: id,
      start: {__MODULE__, :start_link, [args]}
    }
  end

  ## Server callbacks

  def handle_info(:loop, state) do
    send(self(), :loop)
    GenServer.cast(MessageProcessor, {:message, create_dummy_message()})
    Process.sleep(50)
    {:noreply, state}
  end

  # Client API

  def start_link(args) do
    name = Keyword.fetch!(args, :id)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  # Logic
  def create_dummy_message() do
    user_pool = ["George", "John", "Paul", "Ringo", "Mathew"]
    text_pool = ["Donkey Ass", "Spam my bread", "Straight out of the oven"]
    followers = :rand.uniform(10000)
    favourites = :rand.uniform(followers)
    retweets_nr = :rand.uniform(favourites) / 2

    user_id = :rand.uniform(5)
    user_name = Enum.at(user_pool, user_id-1)
    %{
      tweet_id: IdCounter.increment_id(),
      text: text_pool |> Enum.random(),
      hashtags: [],
      followers: followers,
      favourites: favourites,
      retweets_nr: retweets_nr,
      user: user_name,
      user_id: user_id,
      engagement_ratio: 0,
      sentimental_score: 0,
      worker_p: nil,
      redact_p: false,
      sentiment_p: false,
      engagement_p: false
    }
  end
end
