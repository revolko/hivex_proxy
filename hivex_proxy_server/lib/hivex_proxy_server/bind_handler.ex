defmodule HivexProxyServer.BindHandler do
  @moduledoc """
  TODO
   * doc
   * the server read timeout kills the connection after a minute -- implement heart beat
  """

  use ThousandIsland.Handler

  require Logger

  @impl ThousandIsland.Handler
  def handle_connection(_socket, state) do
    Logger.info(message: "Proxy client connected")
    {:continue, state}
  end

  @impl ThousandIsland.Handler
  def handle_data(<<_ver, 1, address::binary>>, socket, state) do
    Logger.info(message: "Handling bind request", data: address)

    {:ok, {ip, port}} = ThousandIsland.Socket.peername(socket)
    Logger.info(ip: ip, port: port)

    {:ok, pid} =
      ThousandIsland.start_link(
        port: 1667,
        handler_module: HivexProxyServer.ListenerHandler,
        handler_options: [client_socket: socket]
      )

    Logger.info(message: "Started listener", port: 1667)
    {:continue, {state, pid}}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, _socket, state) do
    Logger.info(message: "Got random data", data: data)
    {:close, state}
  end

  @impl ThousandIsland.Handler
  def handle_close(_socket, {_state, listener_pid}) do
    Logger.info(message: "Proxy client connection is closed")
    :ok = ThousandIsland.stop(listener_pid)
    Logger.info(message: "Bind listener stopped")
    :ignored
  end

  @impl ThousandIsland.Handler
  def handle_close(_socket, _state) do
    Logger.info(message: "Proxy client connection is closed")
    :ignored
  end
end
