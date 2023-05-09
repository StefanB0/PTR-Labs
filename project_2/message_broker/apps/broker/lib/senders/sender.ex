defmodule Senders.Sender do
  use GenServer
  alias Stores.LetterStore

  # Server API

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    # subscriber_list =
    #   Stores.SubscriberStore.get_subscribers()
    #   |> Enum.map(fn {id, _, _} -> id end)
    #   |> Enum.sort()

    # subscriber_queues =
    #   Enum.reduce(subscriber_list, %{}, fn id, acc ->
    #     topics = Stores.SubscriberStore.get_subscriber_topics(id)
    #     queue = LetterStore.get_entries_by_topics(topics)
    #     Map.put(acc, id, %{queue: queue, online: false, current_letter: nil})
    #   end)


    # state = %{subscriber_list: subscriber_list, subscriber_queues: subscriber_queues}
    state = %{}
    {:ok, state}
  end

  ## Server Logic
  def send_aknowledgement(socket) do
    id = Logic.UserAgent.get_subscriber(socket)
    subscriber = Stores.SubscriberStore.get_subscriber(id)
    # address = Stores.SubscriberStore.get_subscriber_contact_info(id)
    write_to_client("ACK/#{id}\n", subscriber.socket, subscriber.method)
  end

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

  # def compile_batch(state) do
  #   state.subscriber_list
  #   |> Enum.reduce([], fn id, acc ->
  #     if state.subscriber_queues[id].online && state.subscriber_queues[id].current_letter == nil do
  #       letter_id = state.subscriber_queues[id].queue |> Enum.take(1)
  #       [{id, letter_id} | acc]
  #     else
  #       acc
  #     end
  #   end)
  # end

  # def mark_batch_as_sent(batch, state) do
  #   new_subscriber_queues = Enum.reduce(batch, state.subscriber_queues, fn {id, letter_id}, acc ->
  #     q = state.subscriber_queues[id]
  #     Map.put(acc, id, %{queue: q.queue, online: q.online, current_letter: letter_id})
  #   end)
  #   %{state | subscriber_queues: new_subscriber_queues}
  # end

  # def distribute_letters(batch) do
  #   Enum.each(batch, fn {id, letter_id} ->
  #     letter = LetterStore.get_letter(letter_id)
  #     address = Stores.SubscriberStore.get_subscriber_contact_info(id)
  #     write_to_client(letter, address.socket, address.method)
  #   end)
  # end

  ## Server Callbacks

  def handle_cast(:send_letters_loop, state) do
    # batch = compile_batch(state)
    # state = mark_batch_as_sent(batch, state)
    # distribute_letters(batch)

    send_letters_loop()
    {:noreply, state}
  end

  # def handle_cast({:add_letter, letter_id}, state) do
  #   topic = LetterStore.get_letter(letter_id).topic
  #   subscribers = Stores.SubscriberStore.get_subscribers_by_topic(topic)
  #   subscriber_queues = Enum.reduce(subscribers, state.subscriber_queues, fn id, acc ->
  #     q = state.subscriber_queues[id]
  #     new_queue = q.queue ++ [letter_id]
  #     Map.put(acc, id, %{queue: new_queue, online: q.online, current_letter: q.current_letter})
  #   end)
  #   state = %{state | subscriber_queues: subscriber_queues} #
  #   {:noreply, state}
  # end

  # def handle_cast({:add_subscriber, subscriber_id}, state) do
  #   topics = Stores.SubscriberStore.get_subscriber_topics(subscriber_id)
  #   queue = LetterStore.get_entries_by_topics(topics)
  #   subscriber_queues = Map.put(state.subscriber_queues, subscriber_id, %{queue: queue, online: true, current_letter: nil})
  #   state = %{state | subscriber_queues: subscriber_queues, subscriber_list: state.subscriber_list ++ [subscriber_id]}
  #   {:noreply, state}
  # end

  # Client API

  def send_letters_loop do
    GenServer.cast(__MODULE__, :send_letters_loop)
  end
end
