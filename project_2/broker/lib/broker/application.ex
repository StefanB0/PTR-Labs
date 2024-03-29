defmodule Broker.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Stores.StoreSupervisor,
      Senders.SenderSupervisor,
      Logic.LogicSupervisor,
      Listeners.ListenerSupervisor,
    ]

    opts = [strategy: :one_for_one, name: Broker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
