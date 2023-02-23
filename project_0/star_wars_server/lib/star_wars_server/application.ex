defmodule StarWarsServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      StarWarsServer.Database,
      Plug.Cowboy.child_spec(scheme: :http, plug: StarWarsServer.Router, options: [port: 4000])
    ]

    opts = [strategy: :one_for_one, name: StarWarsServer.Supervisor]

    Logger.info("Starting Star Wars Server")

    res = Supervisor.start_link(children, opts)
    StarWarsServer.Database.import("store/data.json")
    res
  end
end
