defmodule ThreadActor do
  def spawn(), do: spawn(__MODULE__, :listen, [])

  def listen do
    receive do
      {:echo, message} -> IO.puts(message)
      {sender_pid} ->
        IO.puts(:ok)
        send(sender_pid, "message received")
    end

    listen()
  end
end
