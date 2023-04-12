defmodule IdCounter do
  use Agent

  # Server API

  def start_link(_args \\ []) do
    state = %{id: 0}
    Agent.start_link(fn -> state end, name: __MODULE__)
  end

  # Client API

  def get_id() do
    Agent.get(__MODULE__, fn state -> state.id end)
  end

  def increment_id() do
    Agent.get_and_update(__MODULE__, fn state -> {state.id, %{state | id: state.id + 1}} end)
  end
end
