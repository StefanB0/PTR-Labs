defmodule StarWarsServer.Application do
  @moduledoc false

  use Application
  require Logger

  alias StarWarsServer.EtsDatabse, as: Database

  @impl true
  def start(_type, _args) do
    children = [
      Database,
      Plug.Cowboy.child_spec(scheme: :http, plug: StarWarsServer.Router, options: [port: 4000])
    ]

    opts = [strategy: :one_for_one, name: StarWarsServer.Supervisor]

    Logger.info("Starting Star Wars Server")

    res = Supervisor.start_link(children, opts)
    Database.import("store/data.json")
    res
  end
end
