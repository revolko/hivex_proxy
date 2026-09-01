defmodule HivexProxyClient.ServerHandler do
  @moduledoc """
  Handles forwarding of data to the registered server and forwarding response through the tunnel.
  """

  require Logger

  @server_timeout 30000

  def handle_data(data, server) do
    with {:ok, socket} <- connect_to_server(server),
         :ok <- send_data(socket, data) do
      receive_response(socket)
    end
  end

  defp connect_to_server(server) do
    Logger.debug(message: "Connecting to server")
    opts = [:binary, active: false]
    :gen_tcp.connect(server.ip, server.port, opts, @server_timeout)
  end

  defp send_data(socket, data) do
    Logger.debug(message: "Sending data to server")
    :gen_tcp.send(socket, data)
  end

  defp receive_response(socket) do
    Logger.debug(message: "Waiting for server data")
    :gen_tcp.recv(socket, 0, @server_timeout)
  end

  defp forward_response(data, tunnel) do
    Logger.debug(message: "Forwarding data to the tunnel", data: data)
    :gen_tcp.send(tunnel, data)
  end
end
