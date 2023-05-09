defmodule SenderTest do
  use ExUnit.Case
  doctest Stores.SubscriberStore

  setup do
    Stores.LetterStore.delete_all_entries()
    {:ok, socket} = :gen_tcp.connect('localhost', 4040, [:binary, active: false])
    {:ok, _connection_message} = :gen_tcp.recv(socket, 0)
    {:ok, socket: socket}
  end

  @tag timeout: 3000
  test "add subscriber and letter", %{socket: socket} do
    assert :ok = :gen_tcp.send(socket, "CONNUSR\n")
    :gen_tcp.recv(socket, 0)
    assert :ok = :gen_tcp.send(socket, "SUB/topic_1\n")
    :gen_tcp.recv(socket, 0)
    assert :ok = :gen_tcp.send(socket, "PUB/topic_1/foobar\n")
    assert {:ok, message} = :gen_tcp.recv(socket, 0)
    assert "PUBACK" == message |> String.trim() |> String.split("/") |> hd()
    # assert {:ok, message} = :gen_tcp.recv(socket, 0)
  end
end
