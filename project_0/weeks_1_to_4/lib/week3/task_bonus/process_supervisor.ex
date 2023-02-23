defmodule ProcessSupervisor do
  use GenServer

  ### Server API

  def init(state) do
    {:ok, state}
  end

  def handle_call({:work, input}, _from, state) do
    {_pid, reference} = Worker.start(input)
    state = Map.put(state, reference, input)
    {:reply, :ok, state}
  end

  def handle_info({:DOWN, reference, :process, _pid, :self_detonation}, state) do
    state[reference] |> Worker.start()
    IO.puts("Task fail! Retry")
    {:noreply, state}
  end

  def handle_info({:DOWN, reference, :process, _pid, :normal}, state) do
    Process.demonitor(reference, [:flush])
    Map.delete(state, reference)
    IO.puts("Task successful")
    {:noreply, state}
  end

  def handle_info(msg, state),
    do:
      (
        IO.inspect(msg)
        {:noreply, state}
      )

  ### Client API
  def start() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def start_worker(input \\ "") do
    GenServer.call(__MODULE__, {:work, input})
  end
end

defmodule Week3.ProcessSupervisor.Worker do
  def randomly_explode() do
    if Enum.random([true, true, true, true, false]) do
      exit(:self_detonation)
    end
  end

  def work(_input) do
    :timer.sleep(200)
    randomly_explode()
    IO.puts("Miau")
  end

  def start(input) do
    spawn_monitor(__MODULE__, :work, [input])
  end
end
