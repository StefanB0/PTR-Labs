defmodule Stores.SubscriberStoreTest do
  use ExUnit.Case, async: true
  doctest Stores.SubscriberStore

  setup_all do
    Stores.SubscriberStore.start_link([])
    :ok
  end

  test "add subscriber" do
    assert Stores.SubscriberStore.add_subscriber(1) == :ok
  end

  test "get subscriber" do
    Stores.SubscriberStore.add_subscriber(1)
    assert Stores.SubscriberStore.get_subscriber(1) == [{1, [], {}}]
  end

  test "get subscribers" do
    Stores.SubscriberStore.add_subscriber(1)
    Stores.SubscriberStore.add_subscriber(2)
    Stores.SubscriberStore.add_subscriber(34)
    assert (Stores.SubscriberStore.get_subscribers() |> Enum.map(fn e -> e |> elem(0) end) |> Enum.sort) == [1, 2, 34]
  end

  test "add subscriber topics" do
    Stores.SubscriberStore.add_subscriber(1)
    assert Stores.SubscriberStore.add_subscriber_topics(1, ["topic"]) == :ok
  end

  test "get subscriber topics" do
    Stores.SubscriberStore.add_subscriber(1)
    Stores.SubscriberStore.add_subscriber_topics(1, ["topic"])
    assert Stores.SubscriberStore.get_subscriber_topics(1) == ["topic"]
  end

  test "remove subscriber" do
    Stores.SubscriberStore.add_subscriber(1)
    assert Stores.SubscriberStore.remove_subscriber(1) == :ok
  end
end
