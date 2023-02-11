defmodule Cat do
  defp randomly_explode() do
    if Enum.random([true, false]) do
      exit(:self_detonation)
    end
  end

  def ask_question(_message) do
    randomly_explode()
    "Miau" |> IO.puts()
  end
end

defmodule LazySupervisorActor do
  use GenServer

  ### GenServer API

  def init(state), do: {:ok, state}

  def handle_call({:question, message}, _from, state) do
    start_worker(message, state)
    {:reply, nil, state}
  end

  ### Client API / Helper functions

  def start() do
    children = [{Task.Supervisor, name: TaskSupervisor.Lazy}]

    Supervisor.start_link(children, strategy: :one_for_one)
    state = TaskSupervisor.Lazy
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def question(message), do: GenServer.call(__MODULE__, {:question, message})

  ### Logic

  defp start_worker(message, state) do
    task = Task.Supervisor.async(state, Cat, :ask_question, [message])
    # Task.async()
    Task.await(task) |> IO.inspect()
  end
end

LazySupervisorActor.start()
LazySupervisorActor.question("How is the weather?")
LazySupervisorActor.question("How is the weather?")
LazySupervisorActor.question("How is the weather?")
LazySupervisorActor.question("How is the weather?")
LazySupervisorActor.question("How is the weather?")

# children = [
#   {Task.Supervisor, name: MyApp.TaskSupervisor}
# ]

# {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)

# task = Task.Supervisor.async(MyApp.TaskSupervisor, fn ->
#   :do_some_work
# end)
