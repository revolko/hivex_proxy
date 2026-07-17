defmodule HivexProxyServer.ListenerHandler do
  @moduledoc """
  TODO
  """

  use ThousandIsland.Handler

  require Logger

  @impl ThousandIsland.Handler
  def handle_data(data, _socket, state) do
    Logger.info(message: "Listener got data", data: data)
    {:continue, state}
  end
end
