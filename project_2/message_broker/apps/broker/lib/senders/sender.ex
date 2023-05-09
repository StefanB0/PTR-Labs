defmodule Senders.Sender do
  use GenServer
  alias Stores.SubscriberStore

  # Server API

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    send_letters_loop()
    state = %{}
    {:ok, state}
  end

  ## Server Logic
  def send_aknowledgement(socket) do
    id = Logic.UserAgent.get_subscriber(socket)
    subscriber = Stores.SubscriberStore.get_subscriber(id)
    write_to_client("ACK/#{id}\n", subscriber.socket, subscriber.method)
  end

  def write_to_client(_message, nil, _method), do: []
  def write_to_client(message, socket, method) do
    case method do
      "tcp" ->
        write_tcp_task(message, socket)
      "mqtt" ->
        :mqtt
    end
  end

  def write_tcp_task(message, socket) do
    Task.Supervisor.start_child(Senders.TaskSupervisor, fn -> :gen_tcp.send(socket, message) end)
  end

  ## Server Callbacks

  def handle_cast(:send_letters_loop, state) do
    Process.sleep(50)

    batch = SubscriberStore.get_letters_batch() |> List.wrap()
    if !Enum.empty?(batch) do
      batch
      |> List.wrap()
      |> Enum.each(fn {socket, message, method} ->
        write_to_client(message, socket, method)
      end)
    end

    send_letters_loop()
    {:noreply, state}
  end

  # Client API

  def send_letters_loop do
    GenServer.cast(__MODULE__, :send_letters_loop)
  end
end
