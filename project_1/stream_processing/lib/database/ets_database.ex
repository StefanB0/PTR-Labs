defmodule ETS.Database do
  use GenServer
  require Logger

  # Server API

  def init(_args) do
    state = %{
      tweets_table: :ets.new(:tweets_table, [:public, :named_table, :set]),
      users_table: :ets.new(:users_table, [:public, :named_table, :set])
    }
    Logger.info("ETS database started")
    Debugger.d_print("ETS database started", :start_up)
    {:ok, state}
  end

  ## Server callbacks

  def handle_call({:get_tweet_by_id, tweet_id}, _from, state) do
    case :ets.lookup(state.tweets_table, tweet_id) do
      [] -> {:reply, nil, state}
      [tweet] -> {:reply, tweet |> elem(1), state}
    end
  end

  def handle_call({:insert_tweet, tweet}, _from, state) do
    Debugger.d_print("Inserting tweet", :ets_database)
    tweet_id = tweet.tweet_id
    user_id = tweet.user_id

    :ets.insert(state.tweets_table, {tweet_id, tweet})
    update_user(user_id, tweet, state.users_table)

    {:reply, :ok, state}
  end

  def handle_call({:delete_tweet, tweet}, _from, state) do
    tweet_id = tweet.tweet_id
    :ets.delete(state.tweets_table, tweet_id)
    user_delete_tweet(tweet.user_id, tweet_id, state.users_table)
    {:reply, :ok, state}
  end

  def handle_call(:get_all_tweets, _from, state) do
    tweets = :ets.tab2list(state.tweets_table)
    tweets = Enum.map(tweets, fn tweet -> tweet |> elem(0) end)
    {:reply, tweets, state}
  end

  def handle_call(:get_all_users, _from, state) do
    users = :ets.tab2list(state.users_table)
    users = Enum.map(users, fn user -> user |> elem(1) end)
    {:reply, users, state}
  end

  def handle_call({:get_tweets_by_user_id, user_id}, _from, state) do
    case :ets.lookup(state.users_table, user_id) do
      [] -> {:reply, [nil], state}
      [user] ->
        user = user |> elem(1)
        tweets = user.tweets
        {:reply, tweets, state}
    end
  end

  # Client API

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def insert_tweet(tweet) do
    GenServer.call(__MODULE__, {:insert_tweet, tweet})
  end

  def delete_tweet(tweet) do
    GenServer.call(__MODULE__, {:delete_tweet, tweet})
  end

  def get_all_tweets do
    GenServer.call(__MODULE__, :get_all_tweets)
  end

  def get_all_users do
    GenServer.call(__MODULE__, :get_all_users)
  end

  def get_tweets_by_user(user) do
    GenServer.call(__MODULE__, {:get_tweets_by_user_id, user})
  end

  def get_tweet_by_id(tweet_id) do
    GenServer.call(__MODULE__, {:get_tweet_by_id, tweet_id})
  end

  # Logic

  defp update_user(user_id, tweet, table) do
    case :ets.lookup(table, user_id) do
      [] ->
        :ets.insert(table, {user_id, %{user_id: user_id,  user_name: tweet.user, tweets: [tweet.tweet_id], tweet_nr: 1}})

      [user] ->
        user = user |> elem(1)
        tweets = user.tweets
        tweets = tweets ++ [tweet.tweet_id]
        user = %{user | tweets: tweets, tweet_nr: user.tweet_nr + 1}
        :ets.insert(table, {user_id, user})
    end
  end

  defp user_delete_tweet(user_id, tweet_id, table) do
    case :ets.lookup(table, user_id) do
      [] -> nil
      [user] ->
        user = user |> elem(1)
        tweets = user.tweets
        tweets = Enum.reject(tweets, &(&1 == tweet_id))
        :ets.insert(table, {user_id, %{user_id: user_id, tweets: tweets}})
    end
  end
end
