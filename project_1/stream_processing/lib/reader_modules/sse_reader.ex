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
        GenServer.cast(MessageProcessor, {:message, message})
    end

    {:noreply, state}
  end

  # Client API

  def start_link(args \\ [id: :sse_reader0, url: "localhost:4000/tweets/1"]) do
    name = Keyword.fetch!(args, :id)
    GenServer.start_link(__MODULE__, args, name: name)
  end
end
