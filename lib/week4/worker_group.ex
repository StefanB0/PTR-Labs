defmodule Week4.WorkerGroup do
  def start_group() do
    w_list = [Worker1, Worker2, Worker3, Worker4, Worker5]

    children =
      Enum.map(w_list, fn w_name ->
        %{id: w_name, start: {Week4.WorkerGroup.WorkerNode, :start_link, []}}
      end)

    {:ok, supervisor_pid} = Supervisor.start_link(children, strategy: :one_for_one)
    {supervisor_pid, get_worker_pids(supervisor_pid)}
  end

  def get_worker_pids(supervisor_pid) do
    Supervisor.which_children(supervisor_pid)
    |> Enum.map(fn {_, pid, _, _} -> pid end)
  end
end

defmodule Week4.WorkerGroup.WorkerNode do
  use GenServer

  ### Server API

  def init(args), do: {:ok, args}

  def handle_call({:message, message}, _from, state) do
    message |> IO.puts()
    {:reply, :ok, state}
  end

  def handle_cast(:kill, _state) do
    exit(:death_by_murder)
    # {:noreply, state}
  end

  ### Client API

  def kill(pid), do: GenServer.cast(pid, :kill)
  def message(pid, message), do: GenServer.call(pid, {:message, message})
  def start_link(), do: GenServer.start_link(__MODULE__, [])
end
