defmodule HivexProxyServer.Tunnel do
  @moduledoc """
  Module defining handlers for tunnel messages.
  """

  require Logger

  defstruct listening: false,
            listener_pid: nil

  def init() do
    %__MODULE__{}
  end

  def handle_frame(
        data,
        _socket,
        tunnel
      ) do
    Logger.debug(message: "Got random data", data: data, tunnel: tunnel)
    {:error, tunnel}
  end
end
