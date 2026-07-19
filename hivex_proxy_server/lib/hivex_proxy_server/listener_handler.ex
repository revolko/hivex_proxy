defmodule HivexProxyServer.ListenerHandler do
  @moduledoc """
  TODO
  """

  use ThousandIsland.Handler

  require Logger

  @impl ThousandIsland.Handler
  def handle_data(data, _socket, state) do
    Logger.info(message: "Listener got data", data: data)

    :ok = ThousandIsland.Socket.send(state[:client_socket], data)

    {:continue, state}
  end
end
