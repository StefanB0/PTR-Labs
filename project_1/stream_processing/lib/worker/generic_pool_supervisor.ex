defmodule GenericPoolSupervisor do
  use Supervisor
  require Logger

  def start_link(args) do
    id = Keyword.fetch!(args, :id)
    Supervisor.start_link(__MODULE__, args, name: id)
  end

  @impl true
  def init(args) do
    name = Keyword.fetch!(args, :id)
    children = Keyword.fetch!(args, :children)

    Logger.info("#{name} started")
    Debugger.d_print("#{name} started", :start_up)
    Supervisor.init(children, strategy: :one_for_one)
  end

  # Client API
  def create_generic_pool(worker_type) do
    # pool = Enum.map(1..pool_size, fn i ->
    #   {worker_type, [id: :"#{worker_type}_#{i}", delay: 1000]}
    # end)
    # {GenericPoolSupervisor, [id: :pool, children: pool]}
    name = worker_type |> Atom.to_string() |> String.trim_leading("Elixir.")
    entry_point = name <> "_load_balancer" |> String.to_atom()
    supervisor_name = name <> "_supervisor" |> String.to_atom()
    %{
      entry: entry_point,
      spec: {GenericPoolSupervisor, [
        id: supervisor_name,
        children: [{worker_type, [id: :"#{worker_type}_1" |> String.to_atom, delay: 1000]}]
        ]}
    }
  end
end
