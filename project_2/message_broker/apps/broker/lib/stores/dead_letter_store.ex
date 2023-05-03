defmodule Stores.DeadLetterStore do
  use GenServer

  # Server API

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    {:ok, dets_table} = :dets.open_file(:"data/dead_letter_store", type: :set)
    counter = :dets.info(dets_table, :size)

    state = %{
      dets_table: dets_table,
      counter: counter
    }

    {:ok, state}
  end

  ## Server Logic

  ## Server Callbacks

  def handle_call({:add_entry, letter}, _from, state) do
    state = %{state | counter: state.counter + 1}
    letter_id = state.counter
    timestamp = DateTime.utc_now()
    contents = letter

    :dets.insert(state.dets_table, {letter_id, timestamp, contents})

    {:reply, state.counter, state}
  end

  def handle_call(:get_entries, _from, state) do
    entries = :dets.select(state.dets_table, [{:"$1", [], [:"$1"]}])

    {:reply, entries, state}
  end

  def handle_call({:delete_entries, entry_ids}, _from, state) do
    for entry_id <- entry_ids do
      :dets.delete(state.dets_table, entry_id)
    end

    {:reply, :ok, state}
  end

  def handle_call(:delete_all_entries, _from, state) do
    :dets.delete_all_objects(state.dets_table)
    state = %{state | counter: 0}

    {:reply, :ok, state}
  end

  # Client API

  def add_entry(letter) do
    GenServer.call(__MODULE__, {:add_entry, letter})
  end

  def get_entries do
    GenServer.call(__MODULE__, :get_entries)
  end

  def delete_entries(entry_ids) do
    GenServer.call(__MODULE__, {:delete_entries, entry_ids})
  end

  def delete_all_entries do
    GenServer.call(__MODULE__, :delete_all_entries)
  end
end
