defmodule Aggregator do
use GenServer
require Logger

# Server API

def init(_args) do
  state = %{tweets: [], finished_tweets: [], batcher_request: false}
  Logger.info("Aggregator worker started")
  Debugger.d_print("Aggregator worker started", :start_up)
  {:ok, state}
end

## Server callbacks

def handle_cast({:tweet, tweet}, state) do
  tweet? = check_exist(tweet, state.tweets)
  state = update_tweet(tweet, state, tweet?)
  state = add_tweet(tweet, state, tweet?)
  state = (state.batcher_request && send_finished_tweet(state)) || state

  # Debugger.d_inspect(tweet, :aggregator)
  {:noreply, state}
end

def handle_cast(:get_tweet, state) do
  state = (state.finished_tweets != [] && send_finished_tweet(state)) || %{state | batcher_request: true}
  {:noreply, state}
end

## Client API

def start_link(args \\ []) do
  GenServer.start_link(__MODULE__, args, name: __MODULE__)
end

def get_tweet() do
  GenServer.cast(__MODULE__, :get_tweet)
end

## Logic

# TODO construct tweet from parts
defp add_tweet(tweet, state, tweet?) do
  unless tweet? do
    tweets = state.tweets ++ [tweet]
    %{state | tweets: tweets}
  else
    state
  end
end

defp update_tweet(tweet, state, tweet?) do
  if tweet? do
    existing_tweet = state.tweets |> Enum.find(&(&1.tweet_id == tweet.tweet_id))
    tweet = %{tweet |
      text: (tweet.redact_p && tweet.text) || (existing_tweet.text),
      sentimental_score: (tweet.sentiment_p && tweet.sentimental_score) || (existing_tweet.sentimental_score),
      engagement_ratio: (tweet.engagement_p && tweet.engagement_ratio) || (existing_tweet.engagement_ratio),
      redact_p: tweet.redact_p || existing_tweet.redact_p,
      sentiment_p: tweet.sentiment_p || existing_tweet.sentiment_p,
      engagement_p: tweet.engagement_p || existing_tweet.engagement_p,
    }

    tweet_finished? = tweet.engagement_p && tweet.redact_p && tweet.sentiment_p
    tweets = state.tweets |> Enum.reject(&(&1.tweet_id == tweet.tweet_id))
    tweets = tweet_finished? && (tweets) || (tweets ++ [tweet])
    tweet_fin = tweet_finished? && ([tweet]) || ([])
    %{state | tweets: tweets, finished_tweets: state.finished_tweets ++ tweet_fin}
  else
    state
  end
end

defp send_finished_tweet(state) do
  unless state.finished_tweets == [] do
    [tweet | list] = state.finished_tweets
    Debugger.d_print("Sending tweet to batcher", :aggregator)
    Debugger.d_inspect(tweet, :aggregator)
    state = %{state | finished_tweets: list}
    Batcher.send_tweet(tweet)
    state
  else
    state
  end
end

defp check_exist(tweet, tweets) do
  tweets |> Enum.any?(&(&1.tweet_id == tweet.tweet_id))
end

# TODO All Workers now route to aggregator
# TODO When receiving a tweet part, aggregator checks if it 'got em all'. On a yes it removes the tweet from memory and forwards it to the batcher.
# TODO On a no, it updates the tweet part in the memory or creates a new one.

# TODO Implement Reactive Pull, instead of pushing everything into the batcher. If aggregator can, it sends tweet to batcher. If it can't, change state and immediately send the next completed tweet to batcher.
end
