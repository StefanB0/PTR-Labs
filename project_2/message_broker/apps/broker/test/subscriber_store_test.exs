defmodule SubscriberStoreTest do
  use ExUnit.Case
  doctest Stores.SubscriberStore

  setup_all do
    Stores.SubscriberStore.start_link([])
    :ok
  end

  setup do
    Stores.SubscriberStore.remove_all_subscribers()
  end

  test "add subscriber" do
    assert Stores.SubscriberStore.add_subscriber(mock_contact_info()) |> is_integer()
  end

  test "get subscriber" do
    id = Stores.SubscriberStore.add_subscriber(mock_contact_info())
    assert Stores.SubscriberStore.get_subscriber(id) |> Map.get(:id) == id
  end

  test "get subscribers" do
    Stores.SubscriberStore.add_subscriber(mock_contact_info())
    Stores.SubscriberStore.add_subscriber(mock_contact_info())
    Stores.SubscriberStore.add_subscriber(mock_contact_info())
    assert length(Stores.SubscriberStore.get_subscribers()) == 3
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
    Stores.SubscriberStore.add_subscriber_topics(id1, ["topic1", "topic2"])
    Stores.SubscriberStore.add_subscriber_topics(id2, ["topic1"])
    Stores.SubscriberStore.add_subscriber_topics(id3, ["topic2"])
    assert Stores.SubscriberStore.get_subscribers_by_topic("topic1") == [id1, id2]
    assert Stores.SubscriberStore.get_subscribers_by_topic("topic2") == [id1, id3]
  end

  def mock_contact_info() do
    %{ip: {127, 0, 0, 1}, socket: nil, method: "tcp"}
  end
end
