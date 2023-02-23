defmodule Week3.MonitorActor do
  def run do
    spawn(Week3.MonitorActor, :listen, [])
  end

  def spawn_and_reply(sender) do
    {pid, _reference} = spawn_monitor(Week3.MonitorActor, :listen, [])
    send(sender, {:new_pid, pid})
  end

  def crash, do: exit(:crash)

  def hello(), do: IO.puts("hello")

  def listen do
    receive do
      {:DOWN, _ref, :process, _from_pid, reason} ->
        IO.puts("Process ended, reason: #{reason}")

      {:crash} ->
        crash()

      {:hello} ->
        hello()

      {:spawn, sender} ->
        spawn_and_reply(sender)
    end

    listen()
  end

  ### Client code

  def shortlisten do
    receive do
      {:new_pid, pid} ->
        pid
    after
      0 -> "nothing in mailbox"
    end
  end
end
