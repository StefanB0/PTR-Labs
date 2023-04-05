defmodule MessageProcessor do
  use GenServer
  require Logger

  # Server API
  def init(args) do
    message_analyst = MessageAnalyst
    load_balancer = Keyword.fetch!(args, :load_balancer)
    state = %{message_analyst: message_analyst, load_balancer: load_balancer}
    Logger.info("MessageProcessor worker started")
    {:ok, state}
  end

  ## Server callbacks
  def handle_cast({:message, message}, state) do
    GenServer.cast(state.message_analyst, {:message, message})
    GenServer.cast(state.load_balancer, {:tweet, message})
    {:noreply, state}
  end

  def handle_cast(:panic_message, state) do
    GenServer.cast(state.load_balancer, {:tweet, :panic_message})
    {:noreply, state}
  end

  # Client API

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # Logic

end
