defmodule MessageAnalyst do
  use GenServer
  require Logger

  # Server API

  def init(args) do
    state = %{tags: %{}}
    spawn_link(run_timer())
    Logger.info("MessageAnalyst worker started")
    {:ok, state}
  end

  ## Server callbacks

  def handle_call({:message, message}, _from, state) do
    state.tags = message
    |> Map.get(:data)
    |> Map.get(:message)
    |> Map.get(:tweet)
    |> Map.get(:entities)
    |> Map.get(:hashtags)
    |> Enum.map(fn item ->
      "#" + Map.get(item, :text)
    end)
    |> Enum.frequencies()
    |> Map.merge(state.tags, fn key, value1, value2 ->
      value1 + value2
    end)

    {:reply, :ok, state}
  end

  def handle_cast(:print, state) do
    state.tags
    |> Enum.max_by(fn {k, v} ->
      v
    end)
    |> Enum.fetch!(0)
    |> Integer.to_string()
    |> &("\n\n---\nMost popular tag is: #{&1}\n---\n\n").()
    |> IO.puts()

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
