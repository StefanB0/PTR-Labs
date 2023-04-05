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
    {:noreply, state}
  end

  # Client API

  def start_link(args) do
    name = Keyword.fetch!(args, :id)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  # Logic
  def create_dummy_message() do
    user_pool = ["George", "John", "Paul", "Ringo"]
    text_pool = ["Donkey Ass", "Spam my bread", "Straight out of the oven"]
    followers = :rand.uniform(10000)
    favourites = :rand.uniform(followers)
    retweets = :rand.uniform(favourites) / 2
    %{
      text: text_pool |> Enum.random(),
      hashtags: [],
      followers: followers,
      favourites: favourites,
      retweets: retweets,
      user: user_pool |> Enum.random(),
      user_id: :rand.uniform(5),
      engagement_ratio: 0,
      sentimental_score: 0,
    }
  end
end
