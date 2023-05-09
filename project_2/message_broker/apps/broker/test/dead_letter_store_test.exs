defmodule DeadLetterStoreTest do
  use ExUnit.Case
  doctest Stores.DeadLetterStore

  setup do
    Stores.DeadLetterStore.delete_all_entries()
  end

  test "add entry" do
    assert Stores.DeadLetterStore.add_entry("letter") |> is_integer()
    assert Stores.DeadLetterStore.add_entry("letter") |> is_integer()
  end

  test "get entries" do
    Stores.DeadLetterStore.add_entry("letter")
    Stores.DeadLetterStore.add_entry("letter")
    entries = Stores.DeadLetterStore.get_entries()
    assert length(entries) == 2
  end

  test "delete entries" do
    og_entries = Stores.DeadLetterStore.get_entries()
    id = Stores.DeadLetterStore.add_entry("letter")
    id2 = Stores.DeadLetterStore.add_entry("letter")
    Stores.DeadLetterStore.delete_entries([id, id2])
    Stores.DeadLetterStore.get_entries()
    Stores.DeadLetterStore.add_entry("letter")
    id4 = Stores.DeadLetterStore.add_entry("letter")
    Stores.DeadLetterStore.delete_entries([id4])
    entries = Stores.DeadLetterStore.get_entries()
    assert length(entries) == length(og_entries) + 1
  end

  test "delete all entries" do
    Stores.DeadLetterStore.get_entries()
    Stores.DeadLetterStore.add_entry("letter")
    Stores.DeadLetterStore.add_entry("letter")
    Stores.DeadLetterStore.get_entries()
    Stores.DeadLetterStore.delete_all_entries()
    entries = Stores.DeadLetterStore.get_entries()
    assert length(entries) == 0
  end
end
