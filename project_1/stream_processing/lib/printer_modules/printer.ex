defmodule Printer do
  use GenServer
  require Logger

  # Server API

  def init(args) do
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
      start: {__MODULE__, :start_link, [args]},
      restart: :transient,
    }
  end

  ## Server callbacks

  def handle_cast({:print, :panic_message}, state) do
    IO.ANSI.format([:red, "Printer #{state.id} panics and crashes"]) |> IO.puts()
    {:stop, :panic, state}
  end

  def handle_cast({:print, message, iterator}, state) do
    delay(state.print_delay)
    print_text(message)

    PrinterPoolManager.print_done(state.id, iterator)
    {:noreply, state}
  end

  # Client API

  def panic(printer_address) do
    GenServer.cast(printer_address, {:print, :panic_message})
  end

  def robin_print(printer_address, message) do
    GenServer.cast(printer_address, {:print, message})
  end

  def least_loaded_print(printer_address, message, iterator) do
    GenServer.cast(printer_address, {:print, message, iterator})
  end

  def start_link(args) do
    name = Keyword.fetch!(args, :id)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  # Logic

  defp delay(time), do: Process.sleep(time)

  defp print_text(message) do
    message
    |> Map.get(:data)
    |> Map.get(:message)
    |> Map.get(:tweet)
    |> Map.get(:text)
    |> censor()
    # |> IO.puts()
  end

  def censor(text) do
    text
    |> String.split()
    |> Enum.map(fn word ->
        censor_word?(word) && (String.graphemes(word) |> Enum.map(fn _ -> "*" end) |> Enum.join())
        || word
      end)
    |> Enum.join(" ")
  end

  defp censor_word?(word), do: CensorList.get_word_list()|> Enum.member?(word)

  # defp append_message_to_file(message) do
  #   message
  #   |> Map.get(:data)
  #   |> Map.get(:message)
  #   |> Jason.encode!()
  #   |> Jason.Formatter.pretty_print()
  #   |> then(&File.write("sample.json", &1, [:append]))

  #   File.write("sample.json", "\n", [:append])
  # end
end
