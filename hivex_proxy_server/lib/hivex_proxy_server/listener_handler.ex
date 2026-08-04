defmodule HivexProxyServer.ListenerHandler do
  @moduledoc """
  The handler of connections for bind listeners.

  This handler has a reference to the associated tunnel in the `state` under `:client_socket` key.
  """

  use ThousandIsland.Handler

  require Logger

  @doc """
  Handle all incoming data and forward the data to the correct tunnel -- `:client_socket`.
  """
  @impl ThousandIsland.Handler
  def handle_data(data, _socket, state) do
    Logger.info(message: "Listener got data", data: data)

    :ok = ThousandIsland.Socket.send(state[:client_socket], data)

    {:continue, state}
  end
end
