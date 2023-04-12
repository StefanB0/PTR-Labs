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

  def child_spec(args) do
    id = Keyword.fetch!(args, :id)

    %{
      id: id,
      start: {__MODULE__, :start_link, [args]}
    }
  end

  # Client API
  def generic_pool_super(id_nr, pool_size, destination, worker_type) do
    name = worker_type |> Atom.to_string() |> String.trim_leading("Elixir.")
    supervisor_name = (name <> "_supervisor") |> String.to_atom()

    pool =
      Enum.map(1..pool_size, fn i ->
        generic_worker_spec(i, id_nr, destination, worker_type)
      end)

    balancer_pool_names = Enum.map(pool, fn {_, sp} -> Keyword.fetch!(sp, :id) end)

    balancer = generic_balancer_spec(id_nr, balancer_pool_names, worker_type)
    balancer_address = (name <> "_load_balancer_#{id_nr}") |> String.to_atom()

    children = pool ++ [balancer]

    %{
      supervisor_address: supervisor_name,
      balancer_address: balancer_address,
      spec: {GenericPoolSupervisor, [id: supervisor_name, children: children]}
    }
  end

  def generic_worker_spec(id, super_id_nr, destination, worker_type) do
    type = worker_type |> Atom.to_string() |> String.trim_leading("Elixir.") |> String.downcase()
    name = "#{type}_#{super_id_nr}_#{id}" |> String.to_atom()
    delay_time = Application.get_env(:stream_processing, :worker_delay)
    {worker_type, [id: name, destination: destination, delay: delay_time]}
  end

  def generic_balancer_spec(id_nr, pool, worker_type) do
    name = worker_type |> Atom.to_string() |> String.trim_leading("Elixir.")
    balancer_name = (name <> "_load_balancer_#{id_nr}") |> String.to_atom()
    {GenericLoadBalancer, [name: balancer_name, pool: pool, worker_type: worker_type]}
  end
end
