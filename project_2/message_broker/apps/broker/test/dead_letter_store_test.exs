defmodule DeadLetterStoreTest do
  use ExUnit.Case, async: true

  setup_all do
    Stores.DeadLetterStore.start_link([])
    :ok
  end

  setup do
    Stores.DeadLetterStore.delete_all_entries()
    :ok
  end

  test "add entry" do
    assert Stores.DeadLetterStore.add_entry("letter") == 1
    assert Stores.DeadLetterStore.add_entry("letter") == 2
  end

  test "get entries" do
    Stores.DeadLetterStore.add_entry("letter")
    Stores.DeadLetterStore.add_entry("letter")
    entries = Stores.DeadLetterStore.get_entries()
    assert length(entries) == 2
    assert entries |> Enum.map(fn e -> e |> elem(0) end) |> Enum.sort() == [1, 2]
  end

  test "delete entries" do
    Stores.DeadLetterStore.add_entry("letter")
    Stores.DeadLetterStore.add_entry("letter")
    entries = Stores.DeadLetterStore.get_entries()
    assert length(entries) == 2
    Stores.DeadLetterStore.delete_entries([1, 2])
    entries = Stores.DeadLetterStore.get_entries()
    assert length(entries) == 0
    Stores.DeadLetterStore.add_entry("letter")
    Stores.DeadLetterStore.add_entry("letter")
    Stores.DeadLetterStore.delete_entries([4])
    entries = Stores.DeadLetterStore.get_entries()
    assert length(entries) == 1
    assert entries |> hd |> elem(0) == 3
  end

  test "delete all entries" do
    Stores.DeadLetterStore.add_entry("letter")
    Stores.DeadLetterStore.add_entry("letter")
    entries = Stores.DeadLetterStore.get_entries()
    assert length(entries) == 2
    Stores.DeadLetterStore.delete_all_entries()
    entries = Stores.DeadLetterStore.get_entries()
    assert length(entries) == 0
  end
end
