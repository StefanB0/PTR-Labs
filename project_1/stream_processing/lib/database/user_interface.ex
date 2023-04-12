defmodule Database.UserInterface do
  require Logger
  alias ETS.Database

  # Server API

  def init(_args) do
    Logger.info("Database user interface started")
    Debugger.d_print("Database user interface started", :start_up)
    IO.puts("Welcome to the database user interface")
    IO.puts("Please enter a command")
    IO.puts("users - returns a list of all users from the database")
    IO.puts("user-t - returns a list of all tweets from a user")
    IO.puts("tweets - returns a list of all tweets from the database")
    IO.puts("tweet - returns a tweet from the database")
    IO.puts("analyst - prints out the most engaged user and the most popular hashtag")
    start()
  end
  # Logic

  defp start() do
    input = IO.gets("Enter command: ") |> String.trim()

    case input do
      "users" ->
        users = Database.get_all_users() |> Enum.map(fn user -> {user.user_name ,user.user_id, {"tweet_count: ", user.tweet_nr}} end)
        IO.puts("Users: #{inspect(users)}")

      "user-t" ->
        user_id = IO.gets("Enter user id: ") |> String.trim() |> String.to_integer
        tweets = Database.get_tweets_by_user(user_id)
        IO.puts("Tweets: #{inspect(tweets)}")

      "tweets" ->
        tweets = Database.get_all_tweets()
        IO.puts("Tweets: #{inspect(tweets)}")

      "tweet" ->
        tweet_id = IO.gets("Enter tweet id: ") |> String.trim() |> String.to_integer
        tweet = Database.get_tweet_by_id(tweet_id)
        IO.puts("Tweet: #{inspect(tweet)}")

      "analyst" ->
        GenServer.cast(MessageAnalyst, :print)

      command ->
        IO.puts("Invalid command #{command}")
    end
    start()
  end

  # Client API

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def child_spec(args \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]}
    }
  end
end
