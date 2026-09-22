defmodule HivexProxyServer.BindHandler do
  @moduledoc """
  TODO
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

  ## Handling data

  The first message that the proxy server expects is the **bind request**. The request triggers
  creation of the `listener` on the given port (read from the request message). After listener is
  started, the handler send **bind response** message to the proxy client and is switched to the
  `listening` state.

  _TO BE IMPLEMENTED_
  ### Listening
  In the listening state, the proxy server redirects proxy client messages to clients of the
  listener. A listener is picked based on the first 7 bytes of a message (version - 1 byte, IP - 
  4 bytes, port - 2 bytes).

  ### Stopping the listener
  The client can stop the listener by simply closing the tunnel.

  ### Health checks
  The proxy client sends the **health check** message every 30 seconds. The health check is started
  the moment the proxy client connects to the proxy server. Health checks make sure that the tunnel
  stays open. Without health checks the TCP tunnel closes after some time without any traffic. By
  default a 1 minute.

  ### Unexpected control message
  In case of the unexpected control message, the server closes the tunnel.
  The client can start a new tunnel which restarts the whole tunnel
  establishing process.
  """

  @sender_ref_length 32

  use ThousandIsland.Handler

  require Logger

  @doc """
  This function is triggered right after the connection to the client is
  established. The `:continue` is returned to keep the connection open.
  """
  @impl ThousandIsland.Handler
  def handle_connection(_socket, state) do
    Logger.info(message: "Proxy client connected")
    tunnel = HivexProxyServer.Tunnel.init()
    {:continue, Map.merge(state, %{tunnel: tunnel})}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, state) do
    case HivexProxyServer.Tunnel.handle_frame(data, socket, state[:tunnel]) do
      {:ok, tunnel} ->
        state = %{state | tunnel: tunnel}
        {:continue, state}

      {:error, reason} ->
        Logger.debug(message: "Failed to handle the frame", details: reason)
        {:close, state}
    end
  end

  @doc """
  Handle calls send to the handler.

  ## Listener request
  Forward listener request/data through the tunnel.
  """
  @impl GenServer
  def handle_call({:listener_request, data}, from, {socket, state}) do
    Logger.debug(message: "Forwarding listener request", data: data)

    Task.Supervisor.start_child(HivexProxyServer.ListenerRequestTaskSupervisor, fn ->
      Logger.debug(message: "Forwarding listener request in Task")
      from_binary = :erlang.term_to_binary(from)

      case ThousandIsland.Socket.send(
             socket,
             <<byte_size(from_binary)::@sender_ref_length>> <>
               from_binary <> data
           ) do
        :ok -> :ok
        {:error, reasone} -> GenServer.reply(from, {:error, reasone})
      end
    end)

    {:noreply, {socket, state}}
  end

  @doc """
  Handles the closing of the tunnel.
  """
  @impl ThousandIsland.Handler
  def handle_close(_socket, _state) do
    Logger.info(message: "Proxy client connection is closed")
    :ignored
  end
end
