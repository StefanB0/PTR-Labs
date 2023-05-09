defmodule LetterStoreTest do
  use ExUnit.Case
  doctest Stores.LetterStore
  alias Stores.LetterStore
  alias Stores.SubscriberStore

  # setup do
  #   LetterStore.delete_all_entries()
  #   SubscriberStore.remove_all_subscribers()
  #   :ok
  # end

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

  test "clear entries" do
    assert true
    # TODO update the test

    # LetterStore.delete_all_entries()
    # delay = Application.get_env(:broker, :clear_message_delay) * 1.1 |> round()
    # timeout = Application.get_env(:broker, :message_timeout) * 1.1 |> round()
    # id = SubscriberStore.add_subscriber(%{ip: {127, 0, 0, 1}, socket: nil, method: "tcp"})
    # id2 = SubscriberStore.add_subscriber(%{ip: {127, 0, 0, 1}, socket: nil, method: "tcp"})
    # SubscriberStore.add_subscriber_topics(id, ["topic44", "topic45"])
    # SubscriberStore.add_subscriber_topics(id2, ["topic46"])

    # LetterStore.add_entry({"letter 1", "topic44"})
    # LetterStore.add_entry({"letter 2", "topic45"})
    # LetterStore.add_entry({"letter 3", "topic46"})

    # Process.sleep(delay)
    # all_entries = LetterStore.get_all_entries()
    # assert length(all_entries) == 3

    # LetterStore.get_entries(id)
    # LetterStore.get_entries(id2)

    # Process.sleep(delay)
    # all_entries = LetterStore.get_all_entries()
    # assert length(all_entries) == 3


    # LetterStore.get_entries(id) |> Enum.each(fn entry -> LetterStore.mark_as_received(id, entry.letter_id) end)
    # Process.sleep(delay)
    # Process.sleep(timeout)
    # all_entries = LetterStore.get_all_entries()
    # assert length(all_entries) == 1

    # LetterStore.get_entries(id2) |> Enum.each(fn entry -> LetterStore.mark_as_received(id2, entry.letter_id) end)

    # Process.sleep(delay)
    # all_entries = LetterStore.get_all_entries()
    # assert length(all_entries) == 1
  end
end
