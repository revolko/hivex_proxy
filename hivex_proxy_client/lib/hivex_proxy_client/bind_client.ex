defmodule HivexProxyClient.BindClient do
  @moduledoc """
  TODO
   * doc
  """

  @server_version 0x1
  @bind_command 0x1
  @error_status_length 8
  @health_check_signal <<0::6*8>>
  @health_check_period 30 * 1000
  @sender_ref_length 32

  use GenServer

  require Logger

  def start_link(%HivexProxyClient.Server{} = server) do
    GenServer.start_link(__MODULE__, server)
  end

  @impl true
  def init(%HivexProxyClient.Server{} = server) do
    binary_port = :binary.encode_unsigned(server.proxy_listener_port)

    with {:ok, socket} <- :gen_tcp.connect(:localhost, 1666, [:binary]),
         :gen_tcp.send(socket, <<@server_version, @bind_command, binary_port::binary-size(2)>>) do
      Logger.info(message: "connected to proxy server")
      schedule_healthcheck()
      {:ok, %{tunnel: socket, server: server}}
    end
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
  def handle_info(
        {:tcp, _port,
         <<sender_length::@sender_ref_length, sender_ref::binary-size(sender_length),
           data::binary>>},
        %{tunnel: tunnel, server: server} = state
      ) do
    Logger.info(message: "Got data from proxy server", data: data)

    {:ok, _} =
      Task.Supervisor.start_child(HivexProxyClient.ServerConnectionsSupervisor, fn ->
        case HivexProxyClient.ServerHandler.handle_data(data, server) do
          {:ok, server_response} ->
            :ok =
              :gen_tcp.send(
                tunnel,
                <<sender_length::@sender_ref_length>> <>
                  sender_ref <> <<0::@error_status_length>> <> server_response
              )

          {:error, _} ->
            :gen_tcp.send(
              tunnel,
              <<sender_length::@sender_ref_length>> <> sender_ref <> <<1::@error_status_length>>
            )
        end
      end)

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
