defmodule MessageProcessor do
  use GenServer
  require Logger

  # Server API
  def init(args) do
    message_analyst = MessageAnalyst
    target = Keyword.fetch!(args, :target)
    state = %{message_analyst: message_analyst, target: target}
    Logger.info("MessageProcessor worker started")
    {:ok, state}
  end

  ## Server callbacks
  def handle_cast({:message, message}, state) do
    # GenServer.cast(state.message_analyst, {:message, message})
    # GenServer.cast(state.target, {:tweet, message})
    state.target ++ [state.message_analyst] |> forward_message(message)
    {:noreply, state}
  end

  def handle_cast(:panic_message, state) do
    # GenServer.cast(state.target, {:panic_tweet})
    forward_panic(state.target)
    {:noreply, state}
  end

  # Client API

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # Logic

  defp forward_message(targets, message) do
    targets |> Enum.each(fn target -> GenServer.cast(target, {:tweet, message}) end)
  end

  defp forward_panic(targets) do
    targets |> Enum.each(fn target -> GenServer.cast(target, {:panic_tweet}) end)
  end

end

# TODO Processor splits the tweet into parts relevant to redacter, sentiment and engagement. Then it sends to all three. Each tweet also gets an id.
# TODO "Bonus Task" before sending a tweet anywhere, recursively get all retweets out of it.
