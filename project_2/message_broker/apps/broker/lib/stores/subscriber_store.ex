defmodule Stores.SubscriberStore do
  use GenServer

  # Server API

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    ets_table = :ets.new(:user_store, [:set, :named_table, :public])
    {:ok, dets_table} = :dets.open_file(:"data/user_store", type: :set)
    :dets.to_ets(dets_table, ets_table)

    state = %{
      dets_table: dets_table,
      ets_table: ets_table
    }

    {:ok, state}
  end

  ## Server Logic

  ## Server Callbacks

  def handle_call({:get_subscriber, subscriber_id}, _from, state) do
    subscriber = :ets.lookup(state.ets_table, subscriber_id)
    {:reply, subscriber, state}
  end

  def handle_call(:get_subscribers, _from, state) do
    subscribers = :ets.tab2list(state.ets_table)
    {:reply, subscribers, state}
  end

  def handle_call({:get_subscriber_topics, subscriber}, _from, state) do
    {_, topics, _} = :ets.lookup(state.ets_table, subscriber) |> hd
    {:reply, topics, state}
  end

  def handle_call({:add_subscriber, subscriber_id}, _from, state) do
    # {subscriber_id, topics, {contact_info}}
    :ets.insert(state.ets_table, {subscriber_id, [], {}})
    {:reply, :ok, state}
  end

  def handle_call({:remove_subscriber, subscriber_id}, _from, state) do
    :ets.delete(state.ets_table, subscriber_id)
    {:reply, :ok, state}
  end

  def handle_call({:add_subscriber_topics, subscriber_id, topics}, _from, state) do
    {_, old_topics, contact_info} = :ets.lookup(state.ets_table, subscriber_id) |> hd
    new_topics = (old_topics ++ topics) |> Enum.uniq()

    :ets.insert(state.ets_table, {subscriber_id, new_topics, contact_info})
    {:reply, :ok, state}
  end

  def handle_call({:remove_subscriber_topics, subscriber_id, topics}, _from, state) do
    {_, old_topics, contact_info} = :ets.lookup(state.ets_table, subscriber_id) |> hd
    new_topics = old_topics -- topics

    :ets.insert(state.ets_table, {subscriber_id, new_topics, contact_info})
    {:reply, :ok, state}
  end

  # Client API

  def get_subscriber(subscriber_id) do
    GenServer.call(__MODULE__, {:get_subscriber, subscriber_id})
  end

  def get_subscribers do
    GenServer.call(__MODULE__, :get_subscribers)
  end

  def get_subscriber_topics(subscriber_id) do
    GenServer.call(__MODULE__, {:get_subscriber_topics, subscriber_id})
  end

  def add_subscriber(subscriber_id) do
    GenServer.call(__MODULE__, {:add_subscriber, subscriber_id})
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

  def stop do
    GenServer.stop(__MODULE__)
  end
end
