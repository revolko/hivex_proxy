defmodule HivexProxyServer.ListenerHandler do
  @moduledoc """
  The handler of connections for bind listeners.

  This handler has a reference to the associated tunnel in the `state` under `:client_socket` key.
  """

  use ThousandIsland.Handler

  require Logger

  @server_call_timeout 30000

  @doc """
  Handle all incoming data and forward the data to the correct tunnel -- `:client_socket`.
  """
  @impl ThousandIsland.Handler
  def handle_data(data, socket, state) do
    Logger.info(message: "Listener got data", data: data)

    {:ok, response} =
      GenServer.call(state[:bind_handler], {:listener_request, data}, @server_call_timeout)

    :ok = ThousandIsland.Socket.send(socket, response)

    {:continue, state}
  end
end
