defmodule HivexProxyClient.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {HivexProxyClient.BindClient, []}
    ]

    opts = [strategy: :one_for_one, name: HivexProxyClient.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
