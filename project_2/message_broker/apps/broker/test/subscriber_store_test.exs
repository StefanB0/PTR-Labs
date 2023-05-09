defmodule SubscriberStoreTest do
  use ExUnit.Case
  doctest Stores.SubscriberStore

  # setup_all do
    # Stores.SubscriberStore.start_link([])
    # :ok
  # end

  # setup do
  #   Stores.SubscriberStore.remove_all_subscribers()
  # end

  test "add subscriber" do
    assert Stores.SubscriberStore.add_subscriber(mock_contact_info()) |> is_integer()
  end

  test "add letter" do
    sub_id = Stores.SubscriberStore.add_subscriber(mock_contact_info())
    let_id = Stores.LetterStore.add_entry({"letter 1", "topic 1"})
    Stores.SubscriberStore.add_letter(sub_id, let_id)
    subscriber = Stores.SubscriberStore.get_subscriber(sub_id)
    assert subscriber.queue == [let_id]
  end

  test "get subscriber" do
    id = Stores.SubscriberStore.add_subscriber(mock_contact_info())
    assert Stores.SubscriberStore.get_subscriber(id) |> Map.get(:id) == id
  end

  test "get subscribers" do
    og_length = length(Stores.SubscriberStore.get_subscribers())
    Stores.SubscriberStore.add_subscriber(mock_contact_info())
    Stores.SubscriberStore.add_subscriber(mock_contact_info())
    Stores.SubscriberStore.add_subscriber(mock_contact_info())
    assert length(Stores.SubscriberStore.get_subscribers()) == og_length + 3
  end

  test "add subscriber topics" do
    id = Stores.SubscriberStore.add_subscriber(mock_contact_info())
    assert Stores.SubscriberStore.add_subscriber_topics(id, ["topic"]) == :ok
  end

  test "get subscriber topics" do
    id = Stores.SubscriberStore.add_subscriber(mock_contact_info())
    Stores.SubscriberStore.add_subscriber_topics(id, ["topic1", "topic2"])
    assert Stores.SubscriberStore.get_subscriber_topics(id) == ["topic1", "topic2"]
  end

  test "remove subscriber" do
    id = Stores.SubscriberStore.add_subscriber(mock_contact_info())
    assert Stores.SubscriberStore.remove_subscriber(id) == :ok
  end

  test "get subscribers by topic" do
    id1 = Stores.SubscriberStore.add_subscriber(mock_contact_info())
    id2 = Stores.SubscriberStore.add_subscriber(mock_contact_info())
    id3 = Stores.SubscriberStore.add_subscriber(mock_contact_info())
    Stores.SubscriberStore.add_subscriber_topics(id1, ["topic1_1", "topic2_1"])
    Stores.SubscriberStore.add_subscriber_topics(id2, ["topic1_1"])
    Stores.SubscriberStore.add_subscriber_topics(id3, ["topic2_1"])
    assert id1 in Stores.SubscriberStore.get_subscribers_by_topic("topic1_1")
    assert id2 in Stores.SubscriberStore.get_subscribers_by_topic("topic1_1")
    assert id1 in Stores.SubscriberStore.get_subscribers_by_topic("topic2_1")
    assert id3 in Stores.SubscriberStore.get_subscribers_by_topic("topic2_1")
  end

  def mock_contact_info() do
    %{ip: {127, 0, 0, 1}, socket: nil, method: "tcp"}
  end
end
