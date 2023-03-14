defmodule Printer do
  use GenServer
  require Logger

  # Server API

  def init(_args) do
    delay_time = Application.fetch_env!(:stream_processing, :print_delay)
    state = %{print_delay: delay_time}
    Logger.info("Printer worker started")
    {:ok, state}
  end

  ## Server callbacks

  def handle_cast({:print, :panic_message}, _from, state) do
    delay(state.print_delay)
    Logger.alert("Printer panics and crashes")
    exit(:panic)
    {:reply, :ok, state}
  end

  def handle_cast({:print, message}, _from, state) do
    delay(state.print_delay)
    print_text(message)
    {:reply, :ok, state}
  end

  # Client API

  def start_link(args \\ [id: :printer0]) do
    name = Keyword.fetch!(args, :id)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  # Logic

  def delay(time) do
    Process.sleep(time)
  end

  def print_text(message) do
    message
    |> Map.get(:data)
    |> Map.get(:message)
    |> Map.get(:tweet)
    |> Map.get(:text)
    |> IO.puts()
  end

  def append_message_to_file(message) do
    message
    |> Map.get(:data)
    |> Map.get(:message)
    |> Jason.encode!()
    |> Jason.Formatter.pretty_print()
    |> then(&File.write("sample.json",&1, [:append]))
    File.write("sample.json","\n", [:append])
  end
end
