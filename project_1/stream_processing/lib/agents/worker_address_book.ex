defmodule Agents.WorkerAddressBook do
  use Agent

  # Server API

  def start_link(_args \\ []) do
    redacter_pool = []
    sentiment_pool = []
    engagement_pool = []
    state = %{redacter_pool: redacter_pool, sentiment_pool: sentiment_pool, engagement_pool: engagement_pool}
    Agent.start_link(fn -> state end, name: __MODULE__)
  end

  # Client API

  def get_pool(pool) do
    Agent.get(__MODULE__, fn state -> Map.fetch!(state, pool) end)
  end

  def add_worker_to_pool(pool, worker) do
    Agent.update(__MODULE__, fn state ->
      Map.update!(state, pool, fn pool -> [worker | pool] end)
    end)
  end

  def remove_worker_from_pool(pool, worker) do
    Agent.update(__MODULE__, fn state ->
      Map.update!(state, pool, fn pool -> Enum.filter(pool, fn w -> w != worker end) end)
    end)
  end
end
