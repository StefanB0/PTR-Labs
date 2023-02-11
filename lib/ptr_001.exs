"Hello PTR" |> IO.puts()
# IO.puts("Bruh?")

# children = [
#   {Task.Supervisor, name: ExampleApp.TaskSupervisor, restart: :transient}
# ]

# {:ok, pid
# } = Supervisor.start_link(children, strategy: :one_for_one)

# {:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> :background_work end)

# Task.await(pid) |> IO.inspect()
