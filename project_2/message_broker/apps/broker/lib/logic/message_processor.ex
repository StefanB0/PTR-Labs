defmodule Logic.MessageProcessor do
  use GenServer
  alias Senders.Sender

  # Server API

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    {:ok, {}}
  end

  ## Server Logic

  def add_subscriber(socket, method) do
    {:ok, {ip, _}} = :inet.sockname(socket)
    address = %{ip: ip, socket: socket, method: method}
    id = Stores.SubscriberStore.add_subscriber(address)
    Logic.UserAgent.add_subscriber(socket, id)

    Sender.write_to_client("CONNACK/#{id}\n", socket, method)
  end

  def reconnect_subscriber(id, socket, method) do
    ip = :inet.sockname(socket) |> elem(1) |> elem(0)
    old_socket = Stores.SubscriberStore.get_subscriber_contact_info(id)
    Logic.UserAgent.delete_subscriber(old_socket)

    address = %{ip: ip, socket: socket, method: method}
    Stores.SubscriberStore.reconnect_subscriber(id, address)
    Logic.UserAgent.add_subscriber(socket, id)
    Sender.write_to_client("CONNACK/#{id}\n", socket, method)
  end

  def add_subscriber_topics(socket, topics) do
    subscriber_id = Logic.UserAgent.get_subscriber(socket)
    topics = topics |> String.split(";") |> Enum.filter(&(&1 != ""))
    Stores.SubscriberStore.add_subscriber_topics(subscriber_id, topics)
    Sender.send_aknowledgement(socket)
  end

  def remove_subscriber_topic(socket, topics) do
    subscriber_id = Logic.UserAgent.get_subscriber(socket)
    topics = topics |> String.split(";") |> Enum.filter(&(&1 != ""))
    Stores.SubscriberStore.remove_subscriber_topics(subscriber_id, topics)
    Sender.send_aknowledgement(socket)
  end

  def publish(topic, message) do
    Stores.LetterStore.add_entry({message, topic})
  end

  def publish_ack(_id) do
    # TODO connect this to durable queue
  end

  ## Server Callbacks

  def handle_cast({:process, message}, state) do
    case message.command do
      "CONNUSR" ->
        add_subscriber(message.address, message.method)
      "RECONN" ->
        reconnect_subscriber(message.id, message.address, message.method)
      "SUB" ->
        add_subscriber_topics(message.address, message.topics)
      "UNSUB" ->
        remove_subscriber_topic(message.address, message.topics)
      "PUB" ->
        publish(message.topic, message.message)
      "PUBACK" ->
        publish_ack(message.id)
    end
    {:noreply, state}
  end

  # Client API

  def process(message) do
    GenServer.cast(__MODULE__, {:process, message})
  end
end
