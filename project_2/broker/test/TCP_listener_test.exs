defmodule TCPListenerTest do
  use ExUnit.Case

  setup do
    {:ok, socket} = :gen_tcp.connect('localhost', 4040, [:binary, active: false])
    {:ok, _connection_message} = :gen_tcp.recv(socket, 0)
    {:ok, socket: socket}
  end

  test "connect" do
    assert {:ok, _socket} = :gen_tcp.connect('localhost', 4040, [:binary, active: false])
  end

  test "connect user", %{socket: socket} do
    assert :ok = :gen_tcp.send(socket, "CONNUSR\n")
    {:ok, message} = :gen_tcp.recv(socket, 0)
    assert "CONNACK" == message |> String.trim() |> String.split("/") |> hd()
    id = message |> String.trim() |> String.split("/") |> tl() |> hd() |> String.to_integer()
    refute Stores.SubscriberStore.get_subscriber(id) |> Enum.empty?()
  end

  test "reconnect user", %{socket: socket} do
    assert :ok = :gen_tcp.send(socket, "CONNUSR\n")
    {:ok, message} = :gen_tcp.recv(socket, 0)
    id = message |> String.trim() |> String.split("/") |> tl() |> hd() |> String.to_integer()

    assert :ok = :gen_tcp.send(socket, "RECONN/#{id}\n")
    {:ok, message} = :gen_tcp.recv(socket, 0)
    assert "CONNACK" == message |> String.trim() |> String.split("/") |> hd()
    assert id == message |> String.trim() |> String.split("/") |> tl() |> hd() |> String.to_integer()
  end

  test "subscribe to topics", %{socket: socket} do
    assert :ok = :gen_tcp.send(socket, "CONNUSR\n")
    {:ok, message} = :gen_tcp.recv(socket, 0)
    id = message |> String.trim() |> String.split("/") |> tl() |> hd() |> String.to_integer()

    assert :ok = :gen_tcp.send(socket, "SUB/topic_1\n")
    {:ok, message} = :gen_tcp.recv(socket, 0)
    assert "ACK" == message |> String.trim() |> String.split("/") |> hd()
    assert Stores.SubscriberStore.get_subscriber(id) |> Map.get(:topics) == ["topic_1"]

    assert :ok = :gen_tcp.send(socket, "SUB/topic_2;topic_3\n")
    assert {:ok, _message} = :gen_tcp.recv(socket, 0)

    assert :ok = :gen_tcp.send(socket, "SUB/topic_2;topic_3\n")
    assert {:ok, _message} = :gen_tcp.recv(socket, 0)
    assert Stores.SubscriberStore.get_subscriber(id) |> Map.get(:topics) == ["topic_1", "topic_2", "topic_3"]
  end

  test "unsubscribe from topics", %{socket: socket} do
    assert :ok = :gen_tcp.send(socket, "CONNUSR\n")
    {:ok, message} = :gen_tcp.recv(socket, 0)
    id = message |> String.trim() |> String.split("/") |> tl() |> hd() |> String.to_integer()

    assert :ok = :gen_tcp.send(socket, "SUB/topic_1;topic_2;topic_3;topic_4;topic_5\n")
    assert {:ok, _message} = :gen_tcp.recv(socket, 0)
    assert Stores.SubscriberStore.get_subscriber(id) |> Map.get(:topics) == ["topic_1", "topic_2", "topic_3", "topic_4", "topic_5"]
    assert :ok = :gen_tcp.send(socket, "UNSUB/topic_2\n")
    assert {:ok, _message} = :gen_tcp.recv(socket, 0)
    assert Stores.SubscriberStore.get_subscriber(id) |> Map.get(:topics) == ["topic_1", "topic_3", "topic_4", "topic_5"]
    assert :ok = :gen_tcp.send(socket, "UNSUB/topic_4;topic_5\n")
    assert {:ok, _message} = :gen_tcp.recv(socket, 0)
    assert Stores.SubscriberStore.get_subscriber(id) |> Map.get(:topics) == ["topic_1", "topic_3"]
    assert :ok = :gen_tcp.send(socket, "UNSUB/topic_4;topic_5\n")
    assert {:ok, _message} = :gen_tcp.recv(socket, 0)
    assert Stores.SubscriberStore.get_subscriber(id) |> Map.get(:topics) == ["topic_1", "topic_3"]
  end

  test "publish message", %{socket: socket} do
    Stores.LetterStore.delete_all_entries()
    assert :ok = :gen_tcp.send(socket, "PUB/cars/ferrari\n")
    assert {:ok, message} = :gen_tcp.recv(socket, 0)
    assert "PUBACK" == message |> String.trim()
    Process.sleep(50)
    refute Stores.LetterStore.get_all_entries() |> Enum.empty?()
    assert Stores.LetterStore.get_all_entries() |> Enum.any?(fn message -> message.topic == "cars" && message.letter == "ferrari" end)
  end
end
