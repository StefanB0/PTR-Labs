defmodule MessageAnalyst do
  use GenServer
  require Logger

  # Server API

  def init(_args) do
    state = %{tags: %{}}
    spawn_link(&run_timer/0)
    Logger.info("MessageAnalyst worker started")
    {:ok, state}
  end

  ## Server callbacks

  def handle_cast({:message, message}, state) do
    state = %{
      state
      | tags:
          message
          |> Map.get(:data)
          |> Map.get(:message)
          |> Map.get(:tweet)
          |> Map.get(:entities)
          |> Map.get(:hashtags)
          |> Enum.map(fn item ->
            Map.get(item, :text)
          end)
          |> Enum.frequencies()
          |> Map.merge(state.tags, fn _key, value1, value2 ->
            value1 + value2
          end)
    }

    {:noreply, state}
  end

  def handle_cast(:print, state) do
    state.tags
    |> Enum.max_by(fn {_k, v} ->
      v
    end)
    |> (&"Most popular tag is: #{elem(&1, 0)}: #{elem(&1, 1)}").()
    |> Logger.notice()

    {:noreply, state}
  end

  # Client API

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # Logic

  def run_timer() do
    Process.sleep(5 * 1000)
    GenServer.cast(MessageAnalyst, :print)
    run_timer()
  end
end
