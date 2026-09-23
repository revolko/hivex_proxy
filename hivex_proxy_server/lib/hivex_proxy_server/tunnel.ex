defmodule HivexProxyServer.Tunnel do
  @moduledoc """
  Module defining handlers for tunnel messages.
  """

  require Logger

  @version 0x1
  @bind_command 0x1
  @health_check_signal <<0::6*8>>
  @sender_ref_length 32
  @error_status_length 8

  defstruct listening: false,
            listener_pid: nil

  def init() do
    %__MODULE__{}
  end

  # BIND frame
  def handle_frame(
        <<@version, @bind_command, port::binary-size(2)>>,
        socket,
        %__MODULE__{listening: false} = tunnel
      ) do
    Logger.debug(message: "Handling bind request", port: port)

    with {:ok, pid} <-
           ThousandIsland.start_link(
             port: :binary.decode_unsigned(port),
             handler_module: HivexProxyServer.ListenerHandler,
             handler_options: [bind_handler: self()]
           ),
         {:ok, {_listen_address, listen_port}} <- ThousandIsland.listener_info(pid),
         :ok <- ThousandIsland.Socket.send(socket, <<@version, @bind_command, listen_port::16>>) do
      {:ok, %{tunnel | listening: true, listener_pid: pid}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # RESPONSE frame
  def handle_frame(
        <<sender_length::@sender_ref_length, sender_ref::binary-size(sender_length),
          error_status::@error_status_length, data::binary>>,
        _socket,
        %__MODULE__{listening: true} = tunnel
      ) do
    Logger.debug(
      message: "Forwarding client proxy data to the listener",
      error_status: error_status,
      data: data
    )

    listener_from = :erlang.binary_to_term(sender_ref)

    case error_status do
      0 ->
        GenServer.reply(listener_from, {:ok, data})

      _ ->
        GenServer.reply(listener_from, {:error, data})
    end

    {:ok, tunnel}
  end

  # HEALTH-CHECK frame
  def handle_frame(<<@version>> <> @health_check_signal, socket, tunnel) do
    Logger.debug(message: "Received health check")

    case ThousandIsland.Socket.send(socket, <<@version>> <> @health_check_signal) do
      :ok ->
        Logger.debug(message: "Health check ACK sent")

      {:error, error} ->
        Logger.warning(message: "Failed to send health check ACK", details: error)
    end

    {:ok, tunnel}
  end

  def handle_frame(
        data,
        _socket,
        tunnel
      ) do
    Logger.debug(message: "Got random data", data: data, tunnel: tunnel)
    {:error, tunnel}
  end

  def forward_request(data, from, socket) do
    from_binary = :erlang.term_to_binary(from)

    send_frame(
      socket,
      <<byte_size(from_binary)::@sender_ref_length>> <>
        from_binary <> data
    )
  end

  def send_frame(socket, data) do
    ThousandIsland.Socket.send(socket, data)
  end
end
