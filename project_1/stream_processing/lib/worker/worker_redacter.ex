defmodule RedacterWorker do
  use GenServer
  require Logger

  # Server API

  def init(args) do
    name = Keyword.fetch!(args, :id)
    destination = Keyword.fetch!(args, :destination)
    state = %{id: name, destination: destination}
    Logger.info("Redacter worker #{name} started")
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

  def handle_cast({:redact_text, text}, state) do
    
    {:noreply, state}
  end

  # Client API
  def start_link(args) do
    name = Keyword.fetch!(args, :id)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  # Logic

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
end
