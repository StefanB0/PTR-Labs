defmodule SupervisorActor do
  use GenServer

  ### Genserver API

  def init(state), do: {:ok, state}

  def handle_cast({:question, message}, state) do
    startWorker(message, state)
    {:noreply, state}
  end

  ### Client API

  def start() do
    children = [{Task.Supervisor, name: SuperActor}]

    {:ok, state} = Supervisor.start_link(children, strategy: :one_for_one)

    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def question(message), do: GenServer.cast(__MODULE__, {:question, message})

  ### Logic

  def startWorker(message, supervisor_pid) do
    {:ok, pid} = Task.Supervisor.start_child(supervisor_pid, Cat.question(message))
    Task.await(pid) |> IO.inspect()
  end

end

defmodule Cat  do
  defp randomly_explode() do
    if Enum.random([true, false]) do
      exit(:TruckCrash)
    end
  end

  def question(_message) do
    randomly_explode()
    "Miau"
  end
end

SupervisorActor.start()
SupervisorActor.question("How are you")
SupervisorActor.question("How are you")
SupervisorActor.question("How are you")
SupervisorActor.question("How are you")
SupervisorActor.question("How are you")
SupervisorActor.question("How are you")
