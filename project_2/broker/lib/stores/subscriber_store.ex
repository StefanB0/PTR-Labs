defmodule Stores.SubscriberStore do
  use GenServer

  @type subscriber_id :: number()

  # Server API

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    ets_table = :ets.new(:user_store, [:set, :named_table, :public])
    {:ok, dets_table} = :dets.open_file(:"data/user_store", type: :set)
    :dets.to_ets(dets_table, ets_table)
    counter = :dets.info(dets_table, :size)

    state = %{
      dets_table: dets_table,
      ets_table: ets_table,
      counter: counter
    }

    {:ok, state}
  end

  def terminate(_, state) do
    :dets.close(state.dets_table)
  end

  ## Server Logic

  def extract_subscriber(ets_table, subscriber_id) do
    :ets.lookup(ets_table, subscriber_id) |> hd |> elem(1)
  end

  def update_tables(subscriber, state) do
    :ets.insert(state.ets_table, {subscriber.id, subscriber})
    :dets.insert(state.dets_table, {subscriber.id, subscriber})
  end

  ## Server Callbacks

  def handle_call({:get_subscriber, subscriber_id}, _from, state) do
    subscriber = extract_subscriber(state.ets_table, subscriber_id)
    {:reply, subscriber, state}
  end

  def handle_call(:get_subscribers, _from, state) do
    subscribers = :ets.tab2list(state.ets_table) |> Enum.map(fn {_, subscriber} -> subscriber.id end)
    {:reply, subscribers, state}
  end

  def handle_call({:get_subscriber_topics, subscriber}, _from, state) do
    topics = :ets.lookup(state.ets_table, subscriber) |> hd |> elem(1) |> Map.get(:topics)
    {:reply, topics, state}
  end

  def handle_call({:get_subscriber_contact_info, subscriber_id}, _from, state) do
    socket = :ets.lookup(state.ets_table, subscriber_id) |> hd |> elem(1) |> Map.get(:socket)
    {:reply, socket, state}
  end

  def handle_call({:get_subscribers_by_topic, topic}, _from, state) do
    subscribers =
      :ets.tab2list(state.ets_table)
      |> Enum.filter(fn {_, subscriber} -> Enum.member?(subscriber.topics, topic) end)
      |> Enum.map(fn {_, subscriber} -> subscriber.id end)
      |> Enum.sort()
    {:reply, subscribers, state}
  end

  def handle_call({:get_top_letter, subscriber_id}, _from, state) do
    subscriber = extract_subscriber(state.ets_table, subscriber_id)
    letter = if subscriber.online && !subscriber.waiting && !Enum.empty?(subscriber.queue)  do
      subscriber.queue |> hd
    else
      []
    end

    subscriber = %{subscriber | waiting: true}
    :ets.insert(state.ets_table, {subscriber_id, subscriber})
    :dets.insert(state.dets_table, {subscriber_id, subscriber})
    {:reply, letter, state}
  end

  def handle_call({:add_subscriber, contact_info}, _from, state) do
    state = %{state | counter: state.counter + 1}
    subscriber = %{id: state.counter, topics: [], online: true, waiting: false, queue: []} |> Map.merge(contact_info)

    :ets.insert(state.ets_table, {state.counter, subscriber})
    :dets.insert(state.dets_table, {state.counter, subscriber})
    {:reply, state.counter, state}
  end

  def handle_call({:reconnect_subscriber, subscriber_id, contact_info}, _from, state) do
    subscriber = extract_subscriber(state.ets_table, subscriber_id) |> Map.merge(contact_info)

    :ets.insert(state.ets_table, {subscriber_id, subscriber})
    :dets.insert(state.dets_table, {subscriber_id, subscriber})
    {:reply, :ok, state}
  end

  def handle_call({:remove_subscriber, subscriber_id}, _from, state) do
    :ets.delete(state.ets_table, subscriber_id)
    :dets.delete(state.dets_table, subscriber_id)
    {:reply, :ok, state}
  end

  def handle_call({:add_subscriber_topics, subscriber_id, topics}, _from, state) do
    subscriber = extract_subscriber(state.ets_table, subscriber_id)
    q = (Stores.LetterStore.get_entries_by_topics(subscriber.topics) ++ subscriber.queue) |> Enum.uniq()
    subscriber = Map.put(subscriber, :topics, (subscriber.topics ++ topics) |> Enum.uniq())
    subscriber = Map.put(subscriber, :queue, q)

    update_tables(subscriber, state)
    {:reply, :ok, state}
  end

  def handle_call({:remove_subscriber_topics, subscriber_id, topics}, _from, state) do
    subscriber = extract_subscriber(state.ets_table, subscriber_id)
    q = (subscriber.queue -- Stores.LetterStore.get_entries_by_topics(subscriber.topics)) |> Enum.uniq()
    subscriber = Map.put(subscriber, :topics, (subscriber.topics -- topics) |> Enum.uniq())
    subscriber = Map.put(subscriber, :queue, q)

    update_tables(subscriber, state)
    {:reply, :ok, state}
  end

  def handle_call(:remove_all_subscribers, _from, state) do
    :ets.delete_all_objects(state.ets_table)
    :dets.delete_all_objects(state.dets_table)
    {:reply, :ok, state}
  end

  def handle_call(:get_letters_batch, _from, state) do
    batch = :ets.tab2list(state.ets_table)
    |> Enum.map(fn {_, subscriber} -> subscriber end)
    |> Enum.reduce([], fn subscriber, acc ->
      if subscriber.online && !subscriber.waiting && !Enum.empty?(subscriber.queue) do
        letter_id = hd(subscriber.queue)
        message = Stores.LetterStore.get_letter(letter_id) |> Map.get(:letter)
        subscriber = %{subscriber | waiting: true}
        update_tables(subscriber, state)
        pack_id = subscriber.id |> Integer.to_string()
        acc ++ [{subscriber.socket, pack_id <> "/" <> message <> "\n", subscriber.method}]
      else
        acc
      end
    end)
    {:reply, batch, state}
  end

  def handle_cast({:add_letter, subscriber_id, letter_id}, state) do
    subscriber = extract_subscriber(state.ets_table, subscriber_id)
    subscriber = Map.put(subscriber, :queue, subscriber.queue ++ [letter_id])

    update_tables(subscriber, state)
    {:noreply, state}
  end

  def handle_cast({:pop_letter, subscriber_id}, state) do
    subscriber = extract_subscriber(state.ets_table, subscriber_id)
    if subscriber.waiting do
      subscriber = %{subscriber | queue: tl(subscriber.queue), waiting: false}
      update_tables(subscriber, state)
    end
    {:noreply, state}
  end

  # Client API

  def get_subscriber(subscriber_id) do
    GenServer.call(__MODULE__, {:get_subscriber, subscriber_id})
  end

  def get_subscribers do
    GenServer.call(__MODULE__, :get_subscribers)
  end

  @spec get_subscriber_topics(number()) :: [charlist()]
  def get_subscriber_topics(subscriber_id) do
    GenServer.call(__MODULE__, {:get_subscriber_topics, subscriber_id})
  end

  def get_subscriber_contact_info(subscriber_id) do
    GenServer.call(__MODULE__, {:get_subscriber_contact_info, subscriber_id})
  end

  def get_subscribers_by_topic(topic) do
    GenServer.call(__MODULE__, {:get_subscribers_by_topic, topic})
  end

  def get_letters_batch() do
    GenServer.call(__MODULE__, :get_letters_batch)
  end

  def pop_letter(subscriber_id) do
    GenServer.cast(__MODULE__, {:pop_letter, subscriber_id})
  end

  def get_top_letter(subscriber_id) do
    GenServer.call(__MODULE__, {:get_top_letter, subscriber_id})
  end

  @spec add_subscriber(any()) :: {:ok, number()}
  def add_subscriber(contact_info) do
    GenServer.call(__MODULE__, {:add_subscriber, contact_info})
  end

  def add_letter(subscriber_id, letter_id) do
    GenServer.cast(__MODULE__, {:add_letter, subscriber_id, letter_id})
  end

  def reconnect_subscriber(subscriber_id, contact_info) do
    GenServer.call(__MODULE__, {:reconnect_subscriber, subscriber_id, contact_info})
  end

  def remove_subscriber(subscriber_id) do
    GenServer.call(__MODULE__, {:remove_subscriber, subscriber_id})
  end

  def add_subscriber_topics(subscriber_id, topics) do
    GenServer.call(__MODULE__, {:add_subscriber_topics, subscriber_id, topics})
  end

  def remove_subscriber_topics(subscriber_id, topics) do
    GenServer.call(__MODULE__, {:remove_subscriber_topics, subscriber_id, topics})
  end

  def remove_all_subscribers do
    GenServer.call(__MODULE__, :remove_all_subscribers)
  end

  def stop do
    GenServer.stop(__MODULE__)
  end
end
