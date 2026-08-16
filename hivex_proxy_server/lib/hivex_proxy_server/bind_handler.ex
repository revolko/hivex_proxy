defmodule HivexProxyServer.BindHandler do
  @moduledoc """
  TODO
   * the server read timeout kills the connection after a minute -- implement heart beat
   * port number check

  The connection handler for a proxy client connection, creating a tunnel.

  ## Tunnel creation

  The creation of the tunnel between the client and the server follows:
  1. the proxy client opens TCP connection to the server
  2. the proxy server accepts the connection
  3. [TBD] the proxy client sends authentication details (TBD what it is)
  4. [TBD] the proxy server validates the authentication details
    - if the details are invalid, the connection is dropped (with reason?)
  5. the proxy client sends **bind request**
    - triggers the proxy server to create a listener
  6. the proxy server responds with **bind response**

  ## Bind request in detail

  The proxy client can request the proxy server to listen for the incoming traffic on the dedicated
  port by issuing the **bind request**.

  Upon the bind request, the proxy server starts up ThousandIsland supervisor on the requested port.
  In addition, the proxy server sends the **bind response** to the client.

  After this point, all traffic that arrives to the new server listener is forwarded to the proxy
  client through the tunnel. The proxy client takes care of forwarding requests to a dedicated
  service/server.
  """

  @version 0x1
  @bind_command 0x1
  @health_check_signal <<0::6*8>>

  use ThousandIsland.Handler

  require Logger

  @doc """
  This function is triggered right after the connection to the client is
  established. The `:continue` is returned to keep the connection open.
  """
  @impl ThousandIsland.Handler
  def handle_connection(_socket, state) do
    Logger.info(message: "Proxy client connected")
    {:continue, state}
  end

  @doc """
  Handles any data sent by the client through the tunnel.

  The first message that the proxy server expects is the **bind request**. The request triggers
  creation of the `listener` on the given port (read from the request message). After listener is
  started, the handler send **bind response** message to the proxy client and is switched to the
  `listening` state.

  _TO BE IMPLEMENTED_
  ## Listening
  In the listening state, the proxy server redirects proxy client messages to clients of the
  listener. A listener is picked based on the first 7 bytes of a message (version - 1 byte, IP - 
  4 bytes, port - 2 bytes).

  ## Stopping the listener
  The client can stop the listener by simply closing the tunnel.

  ## Health checks
  The proxy client sends the **health check** message every 30 seconds. The health check is started
  the moment the proxy client connects to the proxy server. Health checks make sure that the tunnel
  stays open. Without health checks the TCP tunnel closes after some time without any traffic. By
  default a 1 minute.

  ## Unexpected control message
  In case of the unexpected control message, the server closes the tunnel.
  The client can start a new tunnel which restarts the whole tunnel
  establishing process.
  """
  @impl ThousandIsland.Handler
  def handle_data(<<@version, @bind_command, port::binary-size(2)>>, socket, state) do
    Logger.info(message: "Handling bind request", port: port)

    with {:start_listener, {:ok, pid}} <-
           {:start_listener,
            ThousandIsland.start_link(
              port: :binary.decode_unsigned(port),
              handler_module: HivexProxyServer.ListenerHandler,
              handler_options: [client_socket: socket]
            )},
         {:get_listener_info, pid, {:ok, {_listen_address, listen_port}}} <-
           {:get_listener_info, pid, ThousandIsland.listener_info(pid)},
         {:send_bind_response, pid, :ok} <-
           {:send_bind_response, pid,
            ThousandIsland.Socket.send(socket, <<@version, @bind_command, listen_port::16>>)} do
      {:continue, {{:listening, pid}, state}}
    else
      {:start_listener, error} ->
        Logger.error(message: "Unable to start the listener supervisor", details: error)
        {:close, state}

      {:get_listener_info, pid, _error} ->
        Logger.error(message: "Unable to get listener information")
        {:close, {{:listening, pid}, state}}

      {:send_bind_response, pid, {:error, error}} ->
        Logger.error(message: "Failed to send bind response message", details: error)
        {:close, {{:listening, pid}, state}}
    end
  end

  @impl ThousandIsland.Handler
  def handle_data(<<@version>> <> @health_check_signal, socket, state) do
    Logger.debug(message: "Received health check")

    with :ok <- ThousandIsland.Socket.send(socket, <<@version>> <> @health_check_signal) do
      Logger.debug(message: "Health check ACK sent")
    else
      {:error, error} -> Logger.error(message: "Failed to send health check ACK", details: error)
    end

    {:continue, state}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, _socket, {{:listening, _pid}, state}) do
    Logger.info(message: "Got random while listening data", data: data)
    {:close, state}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, _socket, state) do
    Logger.info(message: "Got random data", data: data)
    {:close, state}
  end

  @doc """
  Handles the closing of the tunnel.

  If the handler was in the `listening` state, the listener
  supervisor is stopped. All opened connections on the listener
  are dropped because they cannot be delivered -- the tunnel is
  already down.
  """
  @impl ThousandIsland.Handler
  def handle_close(_socket, {{:listening, listener_pid}, _state}) do
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
