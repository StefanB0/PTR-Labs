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
    (state.target ++ [state.message_analyst]) |> forward_message(message)
    {:noreply, state}
  end

  def handle_cast(:panic_message, state) do
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
