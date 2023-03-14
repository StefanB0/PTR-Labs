defmodule Printer do
  use GenServer
  require Logger

  # Server API

  def init(args) do
    delay_time = Application.fetch_env!(:stream_processing, :print_delay)
    args = [print_delay: delay_time | args]
    Logger.info("Printer worker started")
    {:ok, args}
  end

  ## Server callbacks

  def handle_call({:print, message}, _from, state) do
    state |> Keyword.fetch!(:print_delay) |> delay()
    print_text(message)
    {:reply, :ok, state}
  end

  # Client API

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
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
