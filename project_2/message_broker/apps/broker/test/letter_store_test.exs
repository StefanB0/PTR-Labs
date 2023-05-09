defmodule LetterStoreTest do
  use ExUnit.Case
  doctest Stores.LetterStore
  alias Stores.LetterStore
  alias Stores.SubscriberStore

  setup_all do
    SubscriberStore.start_link([])
    LetterStore.start_link([])
    :ok
  end

  setup do
    LetterStore.delete_all_entries()
    SubscriberStore.remove_all_subscribers()
    :ok
  end

  test "add letter" do
    assert LetterStore.add_entry({"letter", "topic"}) == 1
    assert LetterStore.add_entry({"letter", "topic"}) == 2
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
    LetterStore.add_entry({"letter 1", "topic"})
    LetterStore.add_entry({"letter 2", "topic"})

    entries = LetterStore.get_all_entries()

    assert length(entries) == 2

    assert {:topic, "topic"} in (entries |> hd)
    assert {:letter, "letter 1"} in (entries |> hd)
    assert {:delivery_status, false} in (entries |> hd)
    assert {:waiting_for_delivery, []} in (entries |> hd)

    assert {:topic, "topic"} in (entries |> Enum.at(1))
    assert {:letter, "letter 2"} in (entries |> Enum.at(1))
    assert {:delivery_status, false} in (entries |> Enum.at(1))
    assert {:waiting_for_delivery, []} in (entries |> Enum.at(1))
  end

  test "get user entries" do
    id = SubscriberStore.add_subscriber(%{ip: {127, 0, 0, 1}, socket: nil, method: "tcp"})
    SubscriberStore.add_subscriber_topics(id, ["topic 1", "topic 2"])

    LetterStore.add_entry({"letter 1", "topic 1"})
    LetterStore.add_entry({"letter 2", "topic 2"})
    LetterStore.add_entry({"letter 3", "topic 3"})

    entries = LetterStore.get_entries(id)

    assert length(entries) == 2

    assert Enum.any?(entries, fn entry -> entry.letter == "letter 1" end)
    assert Enum.any?(entries, fn entry -> entry.letter == "letter 2" end)
    refute Enum.any?(entries, fn entry -> entry.letter == "letter 3" end)

    assert Enum.any?(entries, fn entry -> entry.letter == "letter 1" && id in entry.waiting_for_delivery end)
    assert Enum.any?(entries, fn entry -> entry.letter == "letter 2" && id in entry.waiting_for_delivery end)
    refute Enum.any?(entries, fn entry -> entry.letter == "letter 3" && id in entry.waiting_for_delivery end)
  end

  test "mark as received" do
    id = SubscriberStore.add_subscriber(%{ip: {127, 0, 0, 1}, socket: nil, method: "tcp"})
    SubscriberStore.add_subscriber_topics(id, ["topic 1", "topic 2"])

    LetterStore.add_entry({"letter 1", "topic 1"})
    LetterStore.add_entry({"letter 2", "topic 2"})
    LetterStore.add_entry({"letter 3", "topic 3"})

    entries = LetterStore.get_entries(id)

    all_entries = LetterStore.get_all_entries()
    assert Enum.any?(all_entries, fn entry -> entry.letter == "letter 1" && id in entry.waiting_for_delivery && entry.delivery_status == false end)
    assert Enum.any?(all_entries, fn entry -> entry.letter == "letter 2" && id in entry.waiting_for_delivery && entry.delivery_status == false end)

    entries |> Enum.each(fn entry -> LetterStore.mark_as_received(id, entry.letter_id) end)

    all_entries = LetterStore.get_all_entries()
    assert Enum.any?(all_entries, fn entry -> entry.letter == "letter 1" && entry.waiting_for_delivery == [] && entry.delivery_status == true end)
    assert Enum.any?(all_entries, fn entry -> entry.letter == "letter 2" && entry.waiting_for_delivery == [] && entry.delivery_status == true end)
    refute Enum.any?(all_entries, fn entry -> entry.letter == "letter 1" && entry.waiting_for_delivery == [id] end)

    assert length(entries) == 2
  end

  test "clear entries" do
    id = SubscriberStore.add_subscriber(%{ip: {127, 0, 0, 1}, socket: nil, method: "tcp"})
    id2 = SubscriberStore.add_subscriber(%{ip: {127, 0, 0, 1}, socket: nil, method: "tcp"})
    SubscriberStore.add_subscriber_topics(id, ["topic 1", "topic 2"])
    SubscriberStore.add_subscriber_topics(id2, ["topic 2"])
    delay = Application.get_env(:broker, :clear_message_delay) * 1.1 |> round()
    timeout = Application.get_env(:broker, :message_timeout) * 1.1 |> round()

    LetterStore.add_entry({"letter 1", "topic 1"})
    LetterStore.add_entry({"letter 2", "topic 2"})
    LetterStore.add_entry({"letter 3", "topic 3"})

    Process.sleep(delay)
    all_entries = LetterStore.get_all_entries()
    assert length(all_entries) == 3

    LetterStore.get_entries(id)
    LetterStore.get_entries(id2)

    Process.sleep(delay)
    all_entries = LetterStore.get_all_entries()
    assert length(all_entries) == 3

    LetterStore.get_entries(id) |> Enum.each(fn entry -> LetterStore.mark_as_received(id, entry.letter_id) end)

    Process.sleep(delay)
    Process.sleep(timeout)
    all_entries = LetterStore.get_all_entries() #|> Enum.map(fn entry -> {entry.topic, entry.letter, entry.waiting_for_delivery, entry.delivery_status} end)
    assert length(all_entries) == 2

    LetterStore.get_entries(id2) |> Enum.each(fn entry -> LetterStore.mark_as_received(id2, entry.letter_id) end)

    Process.sleep(delay)
    all_entries = LetterStore.get_all_entries() # |> Enum.map(fn entry -> {entry.topic, entry.letter, entry.waiting_for_delivery, entry.delivery_status} end)
    assert length(all_entries) == 1
  end
end
