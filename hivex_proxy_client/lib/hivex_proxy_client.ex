defmodule HivexProxyClient do
  @moduledoc """
  TODO
  """

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor,
      restart: :permanent
    }
  end

  def start_link(_) do
    children = [
      {HivexProxyClient.ConnectionsSupervisor, []},
      {Task.Supervisor, name: HivexProxyClient.ServerConnectionsSupervisor}
    ]

    opts = [strategy: :one_for_one, name: HivexProxyClient.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
