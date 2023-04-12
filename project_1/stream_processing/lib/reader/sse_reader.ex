defmodule SSEReader do
  use GenServer

  require Logger
  # Server API

  def init(args) do
    url = Keyword.fetch!(args, :url)
    EventsourceEx.new(url, stream_to: self())
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

  def handle_info(message, state) do
    case message do
      %{id: _, event: _, data: "{\"message\": panic}"} ->
        GenServer.cast(MessageProcessor, :panic_message)

      message ->
        message = Map.put(message, :data, Jason.decode!(message.data, keys: :atoms))
        # %{
          #   text: message.data.message.tweet.text,
          #   user: message.data.message.tweet.user.screen_name,
          #   user_id: message.data.message.tweet.user.id,
          #   hashtags: message.data.message.tweet.entities.hashtags,
          # }
        # tweet = %{
        #   tweet_id: IdCounter.increment_id(),
        #   text: message.data.message.tweet.text,
        #   hashtags: message.data.message.tweet.entities.hashtags,
        #   followers: message.data.message.tweet.user.followers_count,
        #   favourites: message.data.message.tweet.favorite_count,
        #   retweets_nr: message.data.message.tweet.retweet_count,
        #   user: message.data.message.tweet.user.screen_name,
        #   user_id: message.data.message.tweet.user.id,
        #   engagement_ratio: 0,
        #   sentimental_score: 0,
        #   worker_p: nil,
        #   redact_p: false,
        #   sentiment_p: false,
        #   engagement_p: false,
        # }
        tweet_body = message.data.message.tweet
        tweet = unwrap_tweet(tweet_body)
        retweet = (tweet_body[:retweeted_status] != nil && unwrap_tweet(tweet_body.retweeted_status)) || nil
        unless retweet == nil do
          GenServer.cast(MessageProcessor, {:message, retweet})
        end
        GenServer.cast(MessageProcessor, {:message, tweet})
        Debugger.d_inspect(tweet, :reader)
    end

    {:noreply, state}
  end

  # Client API

  def start_link(args \\ [id: :sse_reader0, url: "localhost:4000/tweets/1"]) do
    name = Keyword.fetch!(args, :id)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  # Logic

  def unwrap_tweet(tweet_body) do
    # tweet_body = message.data.message.tweet
    %{
      tweet_id: IdCounter.increment_id(),
      text: tweet_body.text,
      hashtags: tweet_body.entities.hashtags,
      followers: tweet_body.user.followers_count,
      favourites: tweet_body.favorite_count,
      retweets_nr: tweet_body.retweet_count,
      user: tweet_body.user.screen_name,
      user_id: tweet_body.user.id,
      engagement_ratio: 0,
      sentimental_score: 0,
      worker_p: nil,
      redact_p: false,
      sentiment_p: false,
      engagement_p: false,
    }
  end
end
