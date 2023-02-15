defmodule Semaphore do
  def create_semaphore(n), do: spawn(Semaphore, :semaphore, [3])

  def aquire(semaphore) do
    send(semaphore, {:aquire, self()})

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
      {:aquire, from} ->
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
    Semaphore.aquire(semaphore)
    IO.puts("aquired semaphore")
    :timer.sleep(5000)
    Semaphore.release(semaphore)
    IO.puts("released semaphore")
    :ok
  end
end
