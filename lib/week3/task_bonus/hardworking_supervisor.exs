defmodule HardworkingSupervisor do
  use GenServer

  ### GenServer API

  def init(args) do
    options = [
      name: Worker.Supervisor,
      strategy: :one_for_one
    ]

    DynamicSupervisor.start_link(options)

    {:ok, args}
  end

  def handle_call(:start_worker, _from, state) do
    DynamicSupervisor.start_child(Worker.Supervisor, Cat)
    {:reply, state, state}
  end

  # def handle_info({reference, :ok}, state) do
  #   IO.inspect(reference)
  #   {:noreply, state}
  # end

  # def handle_info({:DOWN, _reference, :process, _pid, :normal}, state), do: {:noreply, state}

  # def handle_info({reference, :ok}, state), do: {:noreply, state}

  ### Client API

  def start_server(arg \\ []) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def start_worker(_message \\ "Hellow") do
    GenServer.call(__MODULE__, :start_worker)
  end
end

defmodule Cat do
  use GenServer

  def init(args) do
    meow()
    {:ok, args}
  end

  def meow() do
    IO.puts("Miau")
    exit(:incident)
  end
end

HardworkingSupervisor.start_server()
HardworkingSupervisor.start_worker()
