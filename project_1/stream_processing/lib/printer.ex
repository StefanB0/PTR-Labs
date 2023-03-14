defmodule Printer do
  use GenServer
  require Logger

  # Server API

  def init(args) do
    # delay_time = Application.fetch_env!(:stream_processing, :print_delay)
    name = Keyword.fetch!(args, :id)
    delay_time = Keyword.fetch!(args, :delay)
    state = %{print_delay: delay_time, id: name}
    Logger.info("Printer worker #{name} started")
    {:ok, state}
  end

  def child_spec(args) do
    id = Keyword.fetch!(args, :id)

    %{
      id: id,
      start: {__MODULE__, :start_link, [args]}
    }
  end

  ## Server callbacks

  def handle_cast({:print, :panic_message}, state) do
    IO.ANSI.format([:red, "Printer #{state.id} panics and crashes"])
    |> IO.puts()
    exit(:panic)
    {:noreply, state}
  end

  def handle_cast({:print, message}, state) do
    delay(state.print_delay)
    print_text(message)
    PrinterPoolManager.print_done(state.id)
    {:noreply, state}
  end

  # Client API

  def robin_print(printer_address, message) do
    GenServer.cast(printer_address, {:print, message})
  end

  def least_loaded_print(printer_address, message) do
    GenServer.cast(printer_address, {:print, message})
  end

  def start_link(args) do
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
    |> then(&File.write("sample.json", &1, [:append]))

    File.write("sample.json", "\n", [:append])
  end
end
