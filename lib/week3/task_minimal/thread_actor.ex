defmodule ThreadActor do
  def spawn(), do: spawn(__MODULE__, :listen, [])

  def listen do
    receive do
      {:echo, message} ->
        IO.puts(message)
    end

    listen()
  end
end
