defmodule Logic.TcpParser do
  use GenServer

  # Server API

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    {:ok, {}}
  end

  ## Server Logic

  def parse_string(message) do
    message
    |> String.trim()
    |> String.split("/")
  end

  ## Server Callbacks

  def handle_cast({:parse, socket, message}, state) do
    split_message = parse_string(message)
    parsed_message = case split_message |> hd() do
      "CONNUSR" ->
        %{command: "CONNUSR", address: socket, method: "tcp"}
      "RECONN" ->
        %{command: "RECONN", id: split_message |> Enum.at(1) |> String.to_integer(), address: socket, method: "tcp"}
      "SUB" ->
        %{command: "SUB", topics: split_message |> Enum.at(1), address: socket}
      "UNSUB" ->
        %{command: "UNSUB", topics: split_message |> Enum.at(1), address: socket}
      "PUB" ->
        %{command: "PUB", topic: split_message |> Enum.at(1), message: split_message |> Enum.at(2)}
      "PUBACK" ->
        %{command: "PUBACK", id: split_message |> Enum.at(1) |> String.to_integer(), address: socket}
      _ ->
        {:ok, {ip, _}} = :inet.sockname(socket)
        Stores.DeadLetterStore.add_entry({:tcp, ip, message, DateTime.utc_now()})
        :error
    end

    unless parsed_message == :error do
      Logic.MessageProcessor.process(parsed_message)
    end
    {:noreply, state}
  end

  # Client API

  def parse(socket, message) do
    GenServer.cast(__MODULE__, {:parse, socket, message})
  end
end
