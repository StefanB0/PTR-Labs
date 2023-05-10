defmodule SenderTest do
  use ExUnit.Case
  doctest Stores.SubscriberStore

  setup do
    {:ok, socket} = :gen_tcp.connect('localhost', 4040, [:binary, active: false])
    {:ok, _connection_message} = :gen_tcp.recv(socket, 0)
    {:ok, socket: socket}
  end

  @tag timeout: 3000
  test "add subscriber and letter", %{socket: socket} do
    assert :ok = :gen_tcp.send(socket, "CONNUSR\n")
    :gen_tcp.recv(socket, 0)
    assert :ok = :gen_tcp.send(socket, "SUB/special_topic\n")
    :gen_tcp.recv(socket, 0)
    assert :ok = :gen_tcp.send(socket, "PUB/special_topic/foobar\n")
    assert {:ok, message} = :gen_tcp.recv(socket, 0)
    assert "PUBACK" == message |> String.trim() |> String.split("/") |> hd()
    assert {:ok, _message} = :gen_tcp.recv(socket, 0)
    Process.sleep(1000)
  end
end
