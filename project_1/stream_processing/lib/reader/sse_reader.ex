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
        tweet = %{
          text: message.data.message.tweet.text,
          user: message.data.message.tweet.user.screen_name,
          user_id: message.data.message.tweet.user.id,
          hashtags: message.data.message.tweet.entities.hashtags,
        }
        GenServer.cast(MessageProcessor, {:message, tweet})
        Debugger.d_inspect(tweet, false)
    end

    {:noreply, state}
  end

  # Client API

  def start_link(args \\ [id: :sse_reader0, url: "localhost:4000/tweets/1"]) do
    name = Keyword.fetch!(args, :id)
    GenServer.start_link(__MODULE__, args, name: name)
  end
end