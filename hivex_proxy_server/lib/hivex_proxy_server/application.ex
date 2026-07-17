defmodule HivexProxyServer.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {ThousandIsland, port: 1666, handler_module: HivexProxyServer.BindHandler}
    ]

    opts = [strategy: :one_for_one, name: HivexProxyServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
