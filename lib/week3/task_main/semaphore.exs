defmodule Semaphore do
  def create_semaphore(n), do: spawn(Semaphore, :semaphore, [3])

  def request(semaphore) do
    send(semaphore, {:request, self()})

    receive do
      :ok ->
        :ok
    end
  end

  def release(semaphore), do: send(semaphore, :release)

  def semaphore(0) do
    receive do
      :release ->
        semaphore(1)
    end
  end

  def semaphore(n) do
    receive do
      {:request, from} ->
        send(from, :ok)
        semaphore(n - 1)

      :release ->
        semaphore(n + 1)
    end
  end
end

defmodule CriticalProcess do
  def run(semaphore) do
    spawn(CriticalProcess, :critical_section, [semaphore])
  end

  def critical_section(semaphore) do
    Semaphore.request(semaphore)
    IO.puts("aquired semaphore")
    :timer.sleep(5000)
    Semaphore.release(semaphore)
    IO.puts("released semaphore")
    :ok
  end
end

s = Semaphore.create_semaphore(3)

for _counter <- 1..9 do
  CriticalProcess.run(s)
end

:timer.sleep(16000)
