defmodule SSEReader do
  use GenServer

  require Logger
  # Server API

  def init(args) do
    id = Keyword.fetch!(args, :id)
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
        IO.puts("PANIC")
      message ->
        dest = Keyword.fetch!(state, :destination)
        GenServer.call(dest, {:message, message})
    end

    {:noreply, state}
  end

  # Client API

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end
end
