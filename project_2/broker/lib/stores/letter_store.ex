defmodule Stores.LetterStore do
  use GenServer

  @type letter_id :: number()
  @type letter :: %{
          letter_id: letter_id(),
          topic: String.t(),
          letter: binary(),
          sender: String.t(),
          letter_timestamp: DateTime.t(),
          delivery_status: boolean(),
          waiting_for_delivery: [number()]
        }

  # Server API

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    ets_table = :ets.new(:letter_store, [:set, :named_table, :public])
    {:ok, dets_table} = :dets.open_file(:"data/letter_store", type: :set)
    :dets.to_ets(dets_table, ets_table)

    counter = :dets.info(dets_table, :size)

    state = %{
      counter: counter,
      clear_message_delay: 0,
      message_timeout: 0,
      dets_table: dets_table,
      ets_table: ets_table
    }

    clear_message_delay = Application.get_env(:broker, :clear_message_delay)
    message_timeout = Application.get_env(:broker, :message_timeout)
    state = %{state | clear_message_delay: clear_message_delay, message_timeout: message_timeout}
    clear_entries(clear_message_delay)

    {:ok, state}
  end

  def terminate(_, state) do
    :dets.close(state.dets_table)
  end

  ## Server Logic

  defp update_counter(nr, dets_table) do
    :dets.insert(dets_table, {"counter", nr})
  end

  ## Server Callbacks

  def handle_call({:add_entry, letter_raw}, _from, state) do
    state = %{state | counter: state.counter + 1}
    update_counter(state.counter, state.dets_table)

    letter_id = state.counter
    {letter_content, topic} = letter_raw
    letter_timestamp = DateTime.utc_now()
    delivery_status = false

    letter_body = %{
      letter_id: letter_id,
      topic: topic,
      letter: letter_content,
      letter_timestamp: letter_timestamp,
      delivery_status: delivery_status,
      waiting_for_delivery: []
    }

    bundle = {letter_id, letter_body}
    :ets.insert(state.ets_table, bundle)
    :dets.insert(state.dets_table, bundle)
    {:reply, letter_id, state}
  end

  def handle_call({:get_letter, letter_id}, _from, state) do
    {_letter_id, letter_body} = :ets.lookup(state.ets_table, letter_id) |> hd
    {:reply, letter_body, state}
  end

  def handle_call({:get_entries, user_id}, _from, state) do
    user_entries =
      :ets.tab2list(state.ets_table)
      |> Enum.filter(fn {_, letter_body} ->
        letter_body.topic in Stores.SubscriberStore.get_subscriber_topics(user_id)
      end)
      |> Enum.map(fn {_, letter_body} -> letter_body end)

    user_entries =
      user_entries
      |> Enum.map(fn letter_body ->
        letter_body = %{
          letter_body | waiting_for_delivery: (user_id not in letter_body.waiting_for_delivery && [user_id | letter_body.waiting_for_delivery] || letter_body.waiting_for_delivery)
        }

        :ets.insert(state.ets_table, {letter_body.letter_id, letter_body})
        :dets.insert(state.dets_table, {letter_body.letter_id, letter_body})
        letter_body
      end)

    {:reply, user_entries, state}
  end

  def handle_call({:get_entries_by_topics, []}, _from, state) do
    {:reply, [], state}
  end

  def handle_call({:get_entries_by_topics, topics}, _from, state) do
    entries =
      :ets.tab2list(state.ets_table)
      |> Enum.map(fn {_, letter_body} -> letter_body end)
      |> Enum.filter(fn letter_body ->
         letter_body |> is_map() && (letter_body.topic in topics)
      end)
      |> Enum.map(& &1.letter_id)

    {:reply, entries, state}
  end

  def handle_call({:mark_as_received, user_id, letter_id}, _from, state) do
    {letter_id, letter_body} = :ets.lookup(state.ets_table, letter_id) |> hd
    waiting_for_delivery = letter_body.waiting_for_delivery |> List.delete(user_id)

    letter_body = %{
      letter_body
      | delivery_status: true,
        waiting_for_delivery: waiting_for_delivery
    }

    :ets.insert(state.ets_table, {letter_id, letter_body})

    {:reply, :ok, state}
  end

  def handle_call(:get_all_entries, _from, state) do
    all_entries =
      :ets.tab2list(state.ets_table) |> Enum.map(fn {_, letter_body} -> letter_body end)

    {:reply, all_entries, state}
  end

  def handle_call(:delete_all_entries, _from, state) do
    :ets.delete_all_objects(state.ets_table)
    :dets.delete_all_objects(state.dets_table)
    state = %{state | counter: 0}

    {:reply, :ok, state}
  end

  def handle_info(:clear_entries, state) do
    all_entries = :ets.tab2list(state.ets_table)

    all_entries
    |> Enum.filter(fn {_, letter_body} ->
      letter_body |> is_map()
      && letter_body.waiting_for_delivery == []
      && letter_body.delivery_status == true
      && (DateTime.diff(DateTime.utc_now(), letter_body.letter_timestamp, :millisecond) > state.message_timeout)
    end)
    |> Enum.each(fn {letter_id, _} ->
      :ets.delete(state.ets_table, letter_id)
      :dets.delete(state.dets_table, letter_id)
    end)

    clear_entries(state.clear_message_delay)
    {:noreply, state}
  end

  # Client API

  def add_entry(letter) do
    GenServer.call(__MODULE__, {:add_entry, letter})
  end

  @spec get_entries(number()) :: [letter()]
  def get_entries(user_id) do
    GenServer.call(__MODULE__, {:get_entries, user_id})
  end

  def get_letter(letter_id) do
    GenServer.call(__MODULE__, {:get_letter, letter_id})
  end

  def get_entries_by_topics(topics) do
    GenServer.call(__MODULE__, {:get_entries_by_topics, topics})
  end

  def mark_as_received(user_id, letter_id) do
    GenServer.call(__MODULE__, {:mark_as_received, user_id, letter_id})
  end

  def get_all_entries do
    GenServer.call(__MODULE__, :get_all_entries)
  end

  def delete_all_entries do
    GenServer.call(__MODULE__, :delete_all_entries)
  end

  def clear_entries(delay) do
    Process.send_after(self(), :clear_entries, delay)
  end
end
