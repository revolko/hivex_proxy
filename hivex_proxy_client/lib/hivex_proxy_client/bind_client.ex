defmodule HivexProxyClient.BindClient do
  @moduledoc """
  TODO
   * doc
  """

  @server_version 0x1
  @bind_command 0x1
  @health_check_signal <<0::6*8>>
  @health_check_period 30 * 1000

  use GenServer

  require Logger

  def start_link(%HivexProxyClient.Server{} = server) do
    GenServer.start_link(__MODULE__, server)
  end

  def close_socket() do
    GenServer.call(__MODULE__, :close)
  end

  @impl true
  def init(%HivexProxyClient.Server{} = server) do
    binary_port = :binary.encode_unsigned(server.proxy_listener_port)

    with {:ok, socket} <- :gen_tcp.connect(:localhost, 1666, [:binary]),
         :gen_tcp.send(socket, <<@server_version, @bind_command>> <> binary_port) do
      Logger.info(message: "connected to proxy server")
      schedule_healthcheck()
      {:ok, %{tunnel: socket, server: server}}
    end
  end

  @impl true
  def handle_call(:close, _from, %{tunnel: socket} = state) do
    :ok = :gen_tcp.close(socket)
    {:stop, :socket_close_call, :ok, state}
  end

  @impl true
  def handle_info(:send_healthcheck, %{tunnel: socket} = state) do
    with :ok <- :gen_tcp.send(socket, <<@server_version>> <> @health_check_signal) do
      Logger.debug(message: "Health check sent")
    else
      {:error, error} -> Logger.error(message: "Failed to send health check", details: error)
    end

    schedule_healthcheck()
    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:tcp, _socket, <<@server_version>> <> @health_check_signal},
        state
      ) do
    Logger.debug(message: "Received health check ACK")
    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:tcp, _port, <<@server_version, @bind_command, ack_port::binary-size(2)>>},
        state
      ) do
    port = :binary.decode_unsigned(ack_port)
    Logger.info(message: "Got bind response from server", port: port)
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp, _port, response}, state) do
    Logger.info(message: "Got response from server", response: response)
    # TODO: send data to the server and send response through the tunnel
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp_closed, _port}, state) do
    Logger.info(message: "TCP connection to the server was closed")
    {:stop, "connection closed by server", state}
  end

  defp schedule_healthcheck do
    Process.send_after(self(), :send_healthcheck, @health_check_period)
  end
end
