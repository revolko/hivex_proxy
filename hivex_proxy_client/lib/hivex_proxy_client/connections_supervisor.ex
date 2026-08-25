defmodule HivexProxyClient.ConnectionsSupervisor do
  @moduledoc """
  `DynamicSupervisor` supervising proxy clients.
  """

  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def register_server(%HivexProxyClient.Server{} = server) do
    DynamicSupervisor.start_child(__MODULE__, {HivexProxyClient.BindClient, server})
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
