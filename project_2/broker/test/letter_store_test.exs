defmodule LetterStoreTest do
  use ExUnit.Case
  doctest Stores.LetterStore
  alias Stores.LetterStore
  alias Stores.SubscriberStore

  test "add letter" do
    assert LetterStore.add_entry({"letter", "topic"}) |> is_integer()
    assert LetterStore.add_entry({"letter", "topic"}) |> is_integer()
  end

  test "get letter" do
    id = LetterStore.add_entry({"letter", "topic"})
    letter = LetterStore.get_letter(id)
    assert letter.letter_id == id
    assert letter.letter == "letter"
    assert letter.topic == "topic"
    assert letter.delivery_status == false
  end

  test "get all letters" do
    og_length = length(LetterStore.get_all_entries())

    LetterStore.add_entry({"letter 1", "topic"})
    LetterStore.add_entry({"letter 2", "topic"})

    entries = LetterStore.get_all_entries()

    assert length(entries) == og_length + 2
  end

  test "get user entries" do
    id = SubscriberStore.add_subscriber(%{ip: {127, 0, 0, 1}, socket: nil, method: "tcp"})
    og_length = length(LetterStore.get_entries(id))
    SubscriberStore.add_subscriber_topics(id, ["topic 1_3", "topic 2_3"])

    LetterStore.add_entry({"letter 1", "topic 1_3"})
    LetterStore.add_entry({"letter 2", "topic 2_3"})
    LetterStore.add_entry({"letter 3", "topic 3_3"})

    entries = LetterStore.get_entries(id)

    assert length(entries) == og_length + 2

    assert Enum.any?(entries, fn entry -> entry.letter == "letter 1" end)
    assert Enum.any?(entries, fn entry -> entry.letter == "letter 2" end)
    refute Enum.any?(entries, fn entry -> entry.letter == "letter 3" end)

    assert Enum.any?(entries, fn entry -> entry.letter == "letter 1" && id in entry.waiting_for_delivery end)
    assert Enum.any?(entries, fn entry -> entry.letter == "letter 2" && id in entry.waiting_for_delivery end)
    refute Enum.any?(entries, fn entry -> entry.letter == "letter 3" && id in entry.waiting_for_delivery end)
  end

  test "mark as received" do
    id = SubscriberStore.add_subscriber(%{ip: {127, 0, 0, 1}, socket: nil, method: "tcp"})
    SubscriberStore.add_subscriber_topics(id, ["topic 1_2", "topic 2_2"])

    LetterStore.add_entry({"letter 1", "topic 1_2"})
    LetterStore.add_entry({"letter 2", "topic 2_2"})
    LetterStore.add_entry({"letter 3", "topic 3_2"})

    entries = LetterStore.get_entries(id)

    all_entries = LetterStore.get_all_entries()
    assert Enum.any?(all_entries, fn entry -> entry.letter == "letter 1" && id in entry.waiting_for_delivery && entry.delivery_status == false end)
    assert Enum.any?(all_entries, fn entry -> entry.letter == "letter 2" && id in entry.waiting_for_delivery && entry.delivery_status == false end)

    entries |> Enum.each(fn entry -> LetterStore.mark_as_received(id, entry.letter_id) end)

    all_entries = LetterStore.get_all_entries()
    assert Enum.any?(all_entries, fn entry -> entry.letter == "letter 1" && entry.waiting_for_delivery == [] && entry.delivery_status == true end)
    assert Enum.any?(all_entries, fn entry -> entry.letter == "letter 2" && entry.waiting_for_delivery == [] && entry.delivery_status == true end)
    refute Enum.any?(all_entries, fn entry -> entry.letter == "letter 1" && entry.waiting_for_delivery == [id] end)
  end
end
