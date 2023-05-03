defmodule Stores.LetterStore do

  use GenServer

  # Server API

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    ets_table = :ets.new(:letter_store, [:set, :named_table, :public])
    {:ok, dets_table} = :dets.open_file(:"data/letter_store", [type: :set])
    :dets.to_ets(dets_table, ets_table)

    filter_counter = fn [] -> 1; c -> c |> hd |> elem(1) end
    counter = :dets.lookup(dets_table, :counter) |> filter_counter.()

    state = %{
      counter: counter,
      dets_table: dets_table,
      ets_table: ets_table
    }

    {:ok, state}
  end

  ## Server Logic

  ## Server Callbacks

  def handle_call({:add_entry, letter}, _from, state) do
    state = %{state | counter: state.counter + 1}
    letter_id = state.counter
    :ets.insert(state.ets_table, {letter_id, letter})
    :dets.insert(state.dets_table, {letter_id, letter})
    {:reply, letter_id, state}
  end

  # Client API

  def add_entry(letter) do
    GenServer.call(__MODULE__, {:add_entry, letter})
  end

  def get_entries(user_id) do
    GenServer.call(__MODULE__, {:get_entries, user_id})
  end

  def mark_as_received(user_id, letter_id) do
    GenServer.call(__MODULE__, {:mark_as_received, user_id, letter_id})
  end

end

# TODO - add a test for this module
# TODO Letters are stored in both ets and dets tables
# TODO DETS TABLE IS READ ON STARTUP OR RESTART
# TODO Each letter has a unique ID, a topic and a list of recipients
# TODO When the recipient list is empty, the letter is deleted
# TODO Special property for letter which does not have a recipient yet
