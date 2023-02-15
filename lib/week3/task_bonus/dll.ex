defmodule DoubleLinkedList do
  use GenServer

  def init(args \\ []) do
    {:ok, args}
  end

  def handle_call(:traverse, _from, {first, last}) do
    {
      :reply,
      go_next(Agent.get(first, & &1), []),
      {first, last}
    }
  end

  def handle_call(:inverse, _from, {first, last}) do
    {
      :reply,
      go_back(Agent.get(last, & &1), []),
      {first, last}
    }
  end

  ### Client API
  def create(list) do
    agent_list = Enum.map(list, fn e -> Agent.start_link(fn -> {e, nil, nil} end) |> elem(1) end)
    link_nodes(agent_list)

    GenServer.start_link(__MODULE__, {List.first(agent_list), List.last(agent_list)},
      name: __MODULE__
    )
  end

  def traverse(), do: GenServer.call(__MODULE__, :traverse)
  def inverse(), do: GenServer.call(__MODULE__, :inverse)

  ### Logic
  # [a | b]
  defp link_nodes([first_agent | [second_agent | agent_list]]) do
    Agent.update(first_agent, fn {state, _succ, pred} -> {state, second_agent, pred} end)
    Agent.update(second_agent, fn {state, succ, _pred} -> {state, succ, first_agent} end)
    link_nodes([second_agent | agent_list])
  end

  defp link_nodes([_single_agent]), do: :ok
  defp link_nodes([]), do: :ok

  defp go_next({state, nil, _last}, list), do: Enum.reverse([state | list])
  defp go_next({state, next, _last}, list), do: go_next(Agent.get(next, & &1), [state | list])
  defp go_back({state, _next, nil}, list), do: Enum.reverse([state | list])
  defp go_back({state, _next, last}, list), do: go_back(Agent.get(last, & &1), [state | list])
end
