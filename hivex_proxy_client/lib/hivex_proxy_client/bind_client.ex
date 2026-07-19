defmodule HivexProxyClient.BindClient do
  @moduledoc """
  TODO
   * doc
   * the server read timeout kills the connection after a minute -- implement heart beat
  """

  @server_version 0x1
  @bind_command 0x1

  use GenServer

  require Logger

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def send_message(message) do
    GenServer.call(__MODULE__, {:send, message})
  end

  def bind_to_port(port) when port >= 1 and port <= 65535 do
    port = :binary.encode_unsigned(port)
    GenServer.call(__MODULE__, {:send, <<@server_version, @bind_command>> <> port})
  end

  def close_socket() do
    GenServer.call(__MODULE__, :close)
  end

  @impl true
  def init([]) do
    {:ok, socket} = :gen_tcp.connect(:localhost, 1666, [:binary])
    Logger.info(message: "connected to proxy server")
    {:ok, socket}
  end

  @impl true
  def handle_call({:send, message}, _from, socket) do
    :ok = :gen_tcp.send(socket, message)
    {:reply, :ok, socket}
  end

  @impl true
  def handle_call(:close, _from, socket) do
    :ok = :gen_tcp.close(socket)
    {:stop, :socket_close_call, :ok, socket}
  end

  @impl true
  def handle_info({:tcp, _port, response}, socket) do
    Logger.info(message: "Got response from server", response: response)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:tcp_closed, _port}, socket) do
    Logger.info(message: "TCP connection to the server was closed")
    {:stop, "connection closed by server", socket}
  end
end
