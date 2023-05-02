defmodule GenericLoadBalancer do
  use GenServer
  require Logger

  # Server API

  def init(args) do
    name = Keyword.fetch!(args, :name)
    worker_type = Keyword.fetch!(args, :worker_type)
    pool = Keyword.fetch!(args, :pool) |> Enum.map(fn p -> {p, 0} end)

    state = %{
      name: name,
      worker_type: worker_type,
      pool: pool
    }

    Logger.info("#{name} started")
    Debugger.d_print("#{name} started", :start_up)
    {:ok, state}
  end

  def child_spec(args) do
    id = Keyword.fetch!(args, :name)

    %{
      id: id,
      start: {__MODULE__, :start_link, [args]},
      restart: :permanent
    }
  end

  ## Server callbacks

  def handle_cast({:add_worker, worker_id}, state) do
    state = state ++ [{worker_id, 0}]
    {:noreply, state}
  end

  def handle_cast({:remove_worker, worker_id}, state) do
    state = state |> Enum.reject(fn {p, _c} -> p == worker_id end)
    {:noreply, state}
  end

  def handle_cast({:panic_tweet}, state) do
    state.pool
    |> Enum.min_by(fn {_p, c} -> c end)
    |> elem(0)
    |> state.worker_type.panic()

    {:noreply, state}
  end

  def handle_cast({:tweet, tweet}, state) do
    {worker_id, _worker_score} = state.pool |> Enum.min_by(fn {_p, c} -> c end)
    state.worker_type.least_loaded(worker_id, tweet, self())

    state = %{
      state
      | pool:
          state.pool |> Enum.map(fn {w, c} -> if w == worker_id, do: {w, c + 1}, else: {w, c} end)
    }

    {:noreply, state}
  end

  def handle_cast({:done, worker_id}, state) do
    state = %{
      state
      | pool:
          state.pool |> Enum.map(fn {w, c} -> if w == worker_id, do: {w, c - 1}, else: {w, c} end)
    }

    {:noreply, state}
  end

  # Client API

  def start_link(args) do
    name = Keyword.fetch!(args, :name)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def worker_done(balancer_id, worker_id) do
    GenServer.cast(balancer_id, {:done, worker_id})
  end
end
