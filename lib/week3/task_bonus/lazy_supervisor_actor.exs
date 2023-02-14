defmodule Cat do
  defp randomly_explode() do
    if Enum.random([true, false]) do
      exit(:self_detonation)
    end
  end

  def ask_question(_message) do
    exit(:self_detonation)
    randomly_explode()
    "Miau" |> IO.puts()
  end
end

# defmodule LazySupervisorActor do
#   use GenServer

#   ### GenServer API

#   def init(state \\ []) do
#     Task.Supervisor.start_link([name: TaskSupervisor.Lazy, max_restarts: 10])
#     {:ok, state}
#   end

#   def handle_call({:question, message}, _from, state) do
#     # {:ok, pid} = Supervisor.start_child(TaskSupervisor.Lazy, &Cat.ask_question/1)
#     Task.Supervisor.async_nolink(TaskSupervisor.Lazy, Cat, :ask_question, [message], restart: :transient)
#     {:reply, nil, state}
#   end

#   # def handle_inof({:DOWN, _ref, :process, _from_pid, reason}) do
#   #   IO.puts("Found the exit call:#{reason}")
#   # end

#   ### Client API / Helper functions

#   def start() do
#     GenServer.start_link(__MODULE__, [], name: __MODULE__)
#   end

#   def question(message), do: GenServer.call(__MODULE__, {:question, message})
# end

# children = [
#   {DynamicSupervisor, name: Lazy.DynamicSupervisor}
# ]

# Supervisor.start_link(children, strategy: :one_for_one)

# for _counter <- 1..4 do
#   DynamicSupervisor.start_child(Lazy.DynamicSupervisor, Cat, :ask_question, ["hello"], restart: :transient)
# end

# Task.Supervisor.start_link(name: LazySupervisor)
# Task.Supervisor.start_child(LazySupervisor, Cat, :ask_question, ["hello"], [restart: :permanent])

children = [
  {Task.Supervisor, name: ExampleApp.TaskSupervisor}
]

{:ok, _pid} = Supervisor.start_link(children, strategy: :one_for_one)

{:ok, _pid} =
  Task.Supervisor.start_child(
    ExampleApp.TaskSupervisor,
    fn ->
      IO.puts("hello")
      raise "this is an error"
    end,
    restart: :permanent
  )
